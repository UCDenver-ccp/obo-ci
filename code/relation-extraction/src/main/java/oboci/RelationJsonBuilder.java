package oboci;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import lombok.Data;

public class RelationJsonBuilder {

	private static void processFile(File relationsFile, Map<String, RelationData> relationIdToDataMap,
									Set<String> roRelations) throws IOException {
		String line = null;
		try (BufferedReader br = new BufferedReader(new FileReader(relationsFile))) {
			while ((line = br.readLine()) != null) {
				String[] toks = line.split("\\t");
				if (toks.length != 3) {
					throw new IllegalStateException("Expected 3 tokens, but observed " + toks.length + " -- " + line);
				}
				String id = toks[0];
				Set<String> labels = new HashSet<String>(Arrays.asList(toks[1].split(",")));
				/*
				 * if there is a legitimate label, then remove any no_labels
				 * that were input during processing in cases when a relation is
				 * used in an ontology but the label is not supplied
				 */
				if (labels.size() > 1) {
					labels.remove("no_label");
				}
				int count = Integer.parseInt(toks[2]);
				boolean restriction = id.contains(" SOME");
				String filename = relationsFile.getName().replaceAll("\\.relations", "").replaceAll("_flat", "");
				if (relationIdToDataMap.containsKey(id)) {
					int fileCount = relationIdToDataMap.get(id).getFileCount() + 1;
					relationIdToDataMap.get(id).setFileCount(fileCount);
					int occurrences = relationIdToDataMap.get(id).getOccurrences() + count;
					String label = relationIdToDataMap.get(id).getLabel();
					for (String l : labels) {
						label += ("," + l);
						if (relationIdToDataMap.get(id).getLabelToFileMap().containsKey(l)) {
							relationIdToDataMap.get(id).getLabelToFileMap().get(l).add(filename);
						} else {
							Set<String> filesWithLabel = new HashSet<String>();
							filesWithLabel.add(filename);
							relationIdToDataMap.get(id).getLabelToFileMap().put(l, filesWithLabel);
						}
					}
					relationIdToDataMap.get(id).setLabel(label);
					relationIdToDataMap.get(id).setOccurrences(occurrences);

					relationIdToDataMap.get(id).getFiles().add(filename);
				} else {
					boolean inRO = isInRO(id, roRelations);
					RelationData rd = new RelationData(id, restriction, inRO);
					List<String> labelList = new ArrayList<String>(labels);
					String label = labelList.get(0);
					for (int i = 1; i < labelList.size(); i++) {
						label += ("," + labelList.get(i));
					}
					rd.setLabel(label);
					for (String l : labels) {
						if (rd.getLabelToFileMap().containsKey(l)) {
							rd.getLabelToFileMap().get(l).add(filename);
						} else {
							Set<String> filesWithLabel = new HashSet<String>();
							filesWithLabel.add(filename);
							rd.getLabelToFileMap().put(l, filesWithLabel);
						}
					}

					rd.setFileCount(1);
					rd.setOccurrences(count);
					rd.getFiles().add(filename);
					relationIdToDataMap.put(id, rd);
				}

			}
		}

	}

	private static boolean isInRO(String id, Set<String> roRelations) {
		return roRelations.contains(id);
	}

	private static Collection<? extends String> getObjectProperties(File file)
			throws FileNotFoundException, IOException {

		Pattern p = Pattern.compile("^<owl:ObjectProperty rdf:about=(.*?)>");

		Set<String> observedProperties = new HashSet<String>();

		String line = null;
		try (BufferedReader br = new BufferedReader(new FileReader(file))) {
			while ((line = br.readLine()) != null) {
				if (line.trim().startsWith("<owl:ObjectProperty rdf:about=")) {
					Matcher m = p.matcher(line.trim());
					if (m.find()) {
						String prop = m.group(1);
						prop = prop.substring(1, prop.length() - 1);
						observedProperties.add(prop);
					} else {
						throw new IllegalArgumentException("could not find match on line: " + line.trim());
					}
				}
			}
		}
		return observedProperties;
	}

	/**
	 * arg[0] is json output file, arg[1] is the directory containing the
	 * relations files
	 *
	 *
	 * @param args
	 * @throws IOException
	 */
	public static void main(String[] args) throws IOException {

		File outputJsonFile = new File(args[0]);
		File relationsFileDirectory = new File(args[1]);

		Map<String, RelationData> relationIdToDataMap = new HashMap<String, RelationData>();

		Set<String> roRelations = new HashSet<String>();
		for (File f : relationsFileDirectory.listFiles()) {
			if (f.getName().startsWith("ro_")) {
				System.out.println("Extracting RO files: " + f);
				roRelations.addAll(getObjectProperties(f));
			}
		}

		for (String relation : roRelations) {
			System.out.println("RO relation: " + relation);
		}

		for (File f : relationsFileDirectory.listFiles()) {
			System.out.println("Processing file: " + f);
			processFile(f, relationIdToDataMap, roRelations);
		}

		// remove redundant labels
		for (RelationData rd : relationIdToDataMap.values()) {
			Set<String> labels = new HashSet<String>();
			for (String label : rd.getLabel().split(",")) {
				labels.add(label.trim());
			}
			if (labels.size() > 1) {
				labels.remove("no_label");
			}
			String labelStr = labels.toString().substring(1, labels.toString().length() - 1);
			rd.setLabel(labelStr.toLowerCase());
		}

		Map<String, Set<String>> labelToRelationIdMap = new HashMap<String, Set<String>>();
		for (RelationData rd : relationIdToDataMap.values()) {
			for (String label : rd.getLabel().split(",")) {
				label = label.trim();
				if (!label.trim().isEmpty() && !label.equals("no_label")) {
					if (labelToRelationIdMap.containsKey(label)) {
						labelToRelationIdMap.get(label).add(rd.getId());
					} else {
						Set<String> ids = new HashSet<String>();
						ids.add(rd.getId());
						labelToRelationIdMap.put(label, ids);
					}
				}
			}
		}

		for (RelationData rd : relationIdToDataMap.values()) {
			for (String label : rd.getLabel().split(",")) {
				label = label.trim();
				if (!label.trim().isEmpty() && !label.equals("no_label")) {
					int count = labelToRelationIdMap.get(label).size();
					if (rd.getSharedLabelCount() < count) {
						rd.setSharedLabelCount(count);
					}
				}
			}
		}

		for (RelationData rd : relationIdToDataMap.values()) {
			int count = rd.getSharedLabelCount() - 1;
			if (count < 0) {
				count = 0;
			}
			rd.setSharedLabelCount(count);
		}

		// for (Entry<String, Set<String>> entry :
		// labelToRelationIdMap.entrySet()) {
		// System.out.println(entry.getKey() + " -- " +
		// entry.getValue().toString());
		// }

		// write json file for visualization
		Gson gson = new GsonBuilder().setPrettyPrinting().create();
		String json = gson.toJson(relationIdToDataMap.values());

		try (BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputJsonFile)))) {
			writer.write(json);
		}

		File owlFileListDirectory = new File(outputJsonFile.getParentFile(), "owl_file_lists");
		File sharedLabelListDirectory = new File(outputJsonFile.getParentFile(), "shared_label_lists");

		owlFileListDirectory.mkdirs();
		sharedLabelListDirectory.mkdirs();

		// write log files for visualization hyperlinks
		for (RelationData rd : relationIdToDataMap.values()) {
			File owlFileListFile = new File(owlFileListDirectory,
					rd.getId().replaceAll("[:/\\. -]", "_") + ".files.txt");
			try (BufferedWriter writer = new BufferedWriter(
					new OutputStreamWriter(new FileOutputStream(owlFileListFile)))) {
				for (String f : rd.getFiles()) {
					writer.write(f + "\n");
				}
			}
			if (rd.getSharedLabelCount() > 0) {
				File sharedLabelListFile = new File(sharedLabelListDirectory,
						rd.getId().replaceAll("[:/\\.]", "_") + ".sharedlabels.txt");
				try (BufferedWriter writer = new BufferedWriter(
						new OutputStreamWriter(new FileOutputStream(sharedLabelListFile)))) {
					writer.write("Label\tRelations with label\n");
					for (String label : rd.getLabel().split(",")) {
						label = label.trim();
						if (!label.trim().isEmpty() && !label.equals("no_label")) {
							Set<String> relationIds = labelToRelationIdMap.get(label);
							writer.write(label + "\t" + relationIds.toString() + "\n");
						}
					}
				}
			}
		}

	}

	@Data
	private static class RelationData {
		private final String id;
		private String label;
		private final boolean restriction;
		private final boolean inRO;
		private int fileCount = 0;
		private int sharedLabelCount = 0;
		private int occurrences = 0;
		private Set<String> files = new HashSet<String>();
		private Map<String, Set<String>> labelToFileMap = new HashMap<String, Set<String>>();

	}

}
