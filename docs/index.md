# Monitoring OBO interoperability

Note, these results are static of Dec 2017. 

## Analysis of individual OBO OWL files
View an [interactive dashboard](dashboard-view/ont_dash.html) summarizing OWL reasoner and cycle detection results for all OWL files cataloged in the OBO Foundry. Hovering over question marks in the dashboard view will display a short description of each visualization.

## OWL reasoner results for pairs of OBOs
The following figures show results from running the ELK and HermiT reasoners over pairs of OWL files cataloged by the OBO Foundry.

[Results for OBO Foundry ontologies only](matrix-view/foundry_pair_matrix.html)<br>
[Results for all OWL files cataloged by the OBO Foundry](matrix-view/pair_matrix.html)

__Figure legend:__ <br>
&nbsp;&nbsp;Upper triangle = results from ELK <br>
&nbsp;&nbsp;Lower triangle = results from HermiT<br>
&nbsp;&nbsp;Red = inconsistent ontology<br>
&nbsp;&nbsp;Orange = >0 incoherent classes observed<br>
&nbsp;&nbsp;Pale green = 0 incoherent classes observed<br>
&nbsp;&nbsp;Grays = process failure due to either timeout after 1 hour, out-of-memory <br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;error (16GB), or some other unspecified reason






