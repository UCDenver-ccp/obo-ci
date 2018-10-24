// This page presents an interactive dashboard for visualizing systematic analyses of
// the Open Biomedical Ontologies. An example entry for the input JSON is shown below:
//
//{
//        "id": "caro",
//        "url": "http://purl.obolibrary.org/obo/caro.owl",
//        "dload": true,
//        "dload_log": "/scratch/Shares/hunter/obo-ci/data/log/download/caro_dload.log",
//        "flat": true,
//        "flat_log": "/scratch/Shares/hunter/obo-ci/data/log/download/caro_flat.log",
//        "elk": true,
//        "elk_log": "/scratch/Shares/hunter/obo-ci/data-all/log/classify/caro_elk.log",
//        "elk_incoherent_count": 0,
//        "hermit_incoherent_count": 0,
//        "hermit": true,
//        "hermit_log": "/scratch/Shares/hunter/obo-ci/data-all/log/classify/caro_hermit.log",
//        "cycles": false,
//        "cycles_log": "/scratch/Shares/hunter/obo-ci/data-all/log/checks/caro_cycles.log",
//        "cycle_count": 0,
//        "foundry": false
//}
//
// Development of this page was highly influenced by https://becomingadatascientist.wordpress.com/tag/dc-js/
//


d3.json("data/relations.json", function (ont_data) {
//var inRestrictionPieChart = dc.pieChart("#in-restriction-pie");
var inROPieChart = dc.pieChart("#in-ro-pie");

var fileCountBarChart = dc.barChart("#file-count-bar-chart");
var sharedLabelsCountBarChart = dc.barChart("#shares-label-bar-chart");
var occurrenceCountBarChart = dc.barChart("#occurrence-count-bar-chart");

var relationCount = dc.dataCount('.dc-data-count');
var relationDataTable = dc.dataTable("#relation-table");

var ndx = crossfilter(ont_data);
var all = ndx.groupAll();


// for inROPieChart
    var inroValue = ndx.dimension(function (d) {
        return d.inRO;
    });
    var inroValueGroup = inroValue.group();

inROPieChart.width(350)
        .height(200)
        .transitionDuration(1500)
        .dimension(inroValue)
        .group(inroValueGroup)
        .radius(90)
        .innerRadius(40)
        .minAngleForLabel(0)
        .label(function(d) { return ''; })
        .legend(dc.legend());

inROPieChart.on('pretransition', function(chart) {
          chart.selectAll('.dc-legend-item text')
              .text('')
            .append('tspan')
              .text(function(d) { return d.name; })
            .append('tspan')
              .attr('x', 85)
              .attr('text-anchor', 'end')
              .text(function(d) { return d.data; });
      });
      inROPieChart.render();

//// for dloadPieChart
//    var inrestrictionValue = ndx.dimension(function (d) {
//        return d.restriction;
//    });
//    var inrestrictionValueGroup = inrestrictionValue.group();
//
//inRestrictionPieChart.width(350)
//        .height(200)
//        .transitionDuration(1500)
//        .dimension(inrestrictionValue)
//        .group(inrestrictionValueGroup)
//        .radius(90)
//        .innerRadius(40)
//        .minAngleForLabel(0)
//        .label(function(d) { return ''; })
//        .legend(dc.legend());
//
//inRestrictionPieChart.on('pretransition', function(chart) {
//          chart.selectAll('.dc-legend-item text')
//              .text('')
//            .append('tspan')
//              .text(function(d) { return d.name; })
//            .append('tspan')
//              .attr('x', 110)
//              .attr('text-anchor', 'end')
//              .text(function(d) { return d.data; });
//      });
//      inRestrictionPieChart.render();

// for file count bar chart
// compute the max for the x-axis
var maxOccurrencesCount = d3.max(ont_data, function (d) {
    return d.occurrences;
});

    var occurrencesCountValue = ndx.dimension(function (d) {
        return (d.occurrences==0) ? 0.1 : d.occurrences * 1.0;

    });
    var occurrencesCountValueGroup = occurrencesCountValue.group();


occurrenceCountBarChart.width(350)
            .height(200)
            .dimension(occurrencesCountValue)
            .group(occurrencesCountValueGroup)
            .transitionDuration(1500)
            .centerBar(true)
            .x(d3.scale.log().nice().domain([1, maxOccurrencesCount+2]))
            .elasticY(true)
            .yAxisLabel("frequency")
            .xAxisLabel("occurrences")
            .xUnits(function(){return 20;})
            .xAxis().ticks(5, ",.0f").tickSize(5, 0);



// for file count bar chart
// compute the max for the x-axis
var maxFilesCount = d3.max(ont_data, function (d) {
    return d.fileCount;
});

    var filesCountValue = ndx.dimension(function (d) {
        return (d.fileCount==0) ? 0.1 : d.fileCount * 1.0;

    });
    var filesCountValueGroup = filesCountValue.group();


fileCountBarChart.width(350)
            .height(200)
            .dimension(filesCountValue)
            .group(filesCountValueGroup)
            .transitionDuration(1500)
            .centerBar(true)
            .x(d3.scale.log().nice().domain([1, maxFilesCount+2]))
            .elasticY(true)
            .yAxisLabel("frequency")
            .xAxisLabel("file count")
            .xUnits(function(){return 20;})
            .xAxis().ticks(5, ",.0f").tickSize(5, 0);


// for shared label count bar chart
var maxSharedLabelsCount = d3.max(ont_data, function (d) {
    return Math.max(d.sharedLabelCount);
});

    var sharedLabelsCountValue = ndx.dimension(function (d) {
        return d.sharedLabelCount * 1.0;

    });
    var sharedLabelsCountValueGroup = sharedLabelsCountValue.group();


sharedLabelsCountBarChart.width(350)
            .height(200)
            .dimension(sharedLabelsCountValue)
            .group(sharedLabelsCountValueGroup)
            .transitionDuration(1500)
            .centerBar(true)
            .x(d3.scale.log().domain([1, maxSharedLabelsCount+2]))
            .elasticY(true)
            .yAxisLabel("frequency")
            .xAxisLabel("shared label count")
            .xUnits(function(){return 20;})
            .xAxis().ticks(5, ",.0f").tickSize(5, 0);


relationCount
        .dimension(ndx)
        .group(all)
        .html({
            some: '<strong>%filter-count</strong> selected out of <strong>%total-count</strong> records' +
                ' | <a href=\'javascript:dc.filterAll(); dc.renderAll();\'>Reset All</a>',
            all: 'All records selected. Please click on the graph to apply filters.'
        });


// For datatable

function getLogUrl(id, tableLabel, suffix) {
    if (tableLabel > 0) {
        path = "data/owl_file_lists/"
        if (suffix = ".sharedLabels.txt") {
            path = "data/shared_label_lists/"
        }

        path = path + id.replace(/[:/\.]/g,"_") + suffix;
        return '<a href="' + path + '">' + tableLabel + '</a>'
    }
    return "0"
}

var tableDimension = ndx.dimension(function (d) { return d.id; });

relationDataTable.width(800).height(800)
    .dimension(tableDimension)
    .group(function(d) { return "List of all Selected Relations"})
    .size(180)
    .columns([
        function(d) { return d.id; },
        function(d) { return d.label; },
        function(d) { return d.inRO; },
        function(d) { return d.occurrences; },
        function(d) { return getLogUrl(d.id, d.fileCount, ".files.txt") },
        function(d) { return getLogUrl(d.id, d.sharedLabelCount, ".sharedlabels.txt") }
    ])
    .sortBy(function(d){ return d.label; })
    .order(d3.ascending);

    dc.renderAll();



});