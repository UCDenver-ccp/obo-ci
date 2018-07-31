package oboci;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.OWLAnnotationAssertionAxiom;
import org.semanticweb.owlapi.model.OWLAnnotationProperty;
import org.semanticweb.owlapi.model.OWLDataFactory;
import org.semanticweb.owlapi.model.OWLLiteral;
import org.semanticweb.owlapi.model.OWLObject;
import org.semanticweb.owlapi.model.OWLObjectProperty;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyCreationException;
import org.semanticweb.owlapi.model.OWLOntologyManager;
import org.semanticweb.owlapi.vocab.OWLRDFVocabulary;

import owltools.graph.OWLGraphEdge;
import owltools.graph.OWLGraphWrapper;
import owltools.graph.OWLQuantifiedProperty;

public class RelationExtractor {

	private static Set<String> getLabels(OWLQuantifiedProperty property, OWLOntology ontology, OWLDataFactory df,
			OWLGraphWrapper graph) {
		OWLAnnotationProperty label = df.getOWLAnnotationProperty(OWLRDFVocabulary.RDFS_LABEL.getIRI());
		Set<String> labels = new HashSet<String>();
		OWLObjectProperty p = property.getProperty();
		if (p != null) {
			OWLObjectProperty prop = graph.getOWLObjectProperty(p.getIRI());
			for (OWLAnnotationAssertionAxiom annotation : ontology.getAnnotationAssertionAxioms(prop.getIRI())) {
				if (annotation.getProperty().equals(label)) {
					if (annotation.getValue() instanceof OWLLiteral) {
						OWLLiteral val = (OWLLiteral) annotation.getValue();
						String l = val.getLiteral().replaceAll("_", " ").replaceAll("-", " ");
						if (l.trim().isEmpty()) {
							l = "no_label";
						}
						labels.add(l);
					}
				}
			}
		}
		if (labels.isEmpty()) {
			labels.add("no_label");
		}
		return labels;
	}

	private static String getLabel(List<OWLQuantifiedProperty> properties, OWLOntology ontology, OWLDataFactory df,
			OWLGraphWrapper graph) {
		String labelStr = "";
		for (OWLQuantifiedProperty prop : properties) {
			Set<String> labels = getLabels(prop, ontology, df, graph);
			for (String label : labels) {
				labelStr += (label + ",");
			}
			if (labelStr.length() > 0) {
				// remove trailing comma
				labelStr = labelStr.substring(0, labelStr.length() - 1);
			}
			labelStr = labelStr + "|";
		}
		// remove trailing pipe
		labelStr = labelStr.substring(0, labelStr.length() - 1);
		return labelStr;
	}

	private static String getPropString(OWLQuantifiedProperty prop) {
		if (prop.getProperty() != null) {
			return prop.getProperty().getIRI().toString();
		} else {
			return prop.toString();
		}
	}

	public static void main(String[] args) throws IOException, OWLOntologyCreationException {

		OWLOntologyManager inputOntologyManager = OWLManager.createOWLOntologyManager();
		OWLOntology ont = inputOntologyManager.loadOntologyFromOntologyDocument(new File(args[0]));
		OWLGraphWrapper graph = new OWLGraphWrapper(ont);
		OWLDataFactory df = inputOntologyManager.getOWLDataFactory();
		int totalClassCount = graph.getAllOWLObjects().size();
		int count = 0;

		Map<String, Integer> relationCountMap = new HashMap<String, Integer>();
		Map<String, String> relationToLabelMap = new HashMap<String, String>();

		try {
			for (OWLObject owlObject : graph.getAllOWLObjects()) {
				if (count++ % 10000 == 0) {
					System.out.println("Progress: " + (count - 1) + " of " + totalClassCount);
				}

				Set<OWLGraphEdge> edges = graph.getOutgoingEdges(owlObject);
				for (OWLGraphEdge edge : edges) {
					for (OWLQuantifiedProperty prop : edge.getQuantifiedPropertyList()) {
						String propStr = getPropString(prop);
						Set<String> label = getLabels(prop, ont, df, graph);
						String labelStr = label.toString().substring(1, label.toString().length() - 1);
						if (labelStr.trim().isEmpty()) {
							throw new IllegalStateException(
									"empty label for " + edge.getQuantifiedPropertyList().toString());
						}
						if (!relationToLabelMap.containsKey(propStr)) {
							relationToLabelMap.put(propStr, labelStr);
						}
						if (relationCountMap.containsKey(propStr)) {
							int propcount = relationCountMap.get(propStr) + 1;
							relationCountMap.remove(propStr);
							relationCountMap.put(propStr, propcount);
						} else {
							relationCountMap.put(propStr, 1);
						}
					}
				}
			}

			BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(new File(args[1]))));
			try {
				for (Entry<String, Integer> entry : relationCountMap.entrySet()) {
					writer.write(entry.getKey() + "\t" + relationToLabelMap.get(entry.getKey()) + "\t"
							+ entry.getValue() + "\n");
				}
			} finally {
				writer.close();
			}
		} finally {
			graph.close();
		}

	}

}
