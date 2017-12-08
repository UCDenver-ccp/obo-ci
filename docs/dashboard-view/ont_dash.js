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


d3.json("data/ont-dash.json", function (ont_data) {

var foundryPieChart = dc.pieChart("#fc-pie");
var dloadPieChart = dc.pieChart("#dload-pie");
var importsPieChart = dc.pieChart("#imports-pie");
var elkPieChart = dc.pieChart("#elk-pie");
var hermitPieChart = dc.pieChart("#hermit-pie");
var cyclePieChart = dc.pieChart("#cycle-pie");
var cycleCountBarChart = dc.barChart("#cycle-bar-chart");
var elkIncoherentCountBarChart = dc.barChart("#elk-incoherent-bar-chart");
var hermitIncoherentCountBarChart = dc.barChart("#hermit-incoherent-bar-chart");
var ontologyCount = dc.dataCount('.dc-data-count');
var ontologyDataTable = dc.dataTable("#ontology-table");

var ndx = crossfilter(ont_data);
var all = ndx.groupAll();


function foundryLabel(raw) {
        return (raw) ? "foundry" : "candidate";
}

function downloadLabel(raw) {
    return (raw) ? "downloadable" : "unavailable";
}

function importsLabel(raw) {
    switch(raw) {
        case null:
            return "n/a";
        case true:
            return "resolvable";
        case false:
            return "unresolvable";
        default:
            console.log("unhandled imports label: " + raw)
        return raw;
 }
}

function hasCycleLabel(raw) {
        switch(raw) {
            case "fail":
                return "failure";
            case "timeout":
                return "timeout";
            case true:
                return "has_cycle";
            case false:
                return "no_cycles";
            case null:
                return "n/a"
            default:
                console.log("unhandled cycle label: " + raw)
                return raw;
        }
}

function reasonerLabel(raw, incoherent_count) {
    switch(raw) {
            case "inconsistent":
                return "inconsistent";
            case "out-of-memory":
                return "out-of-memory";
            case "timeout":
                return "timeout";
            case true:
                return (incoherent_count > 0) ? "incoherent" : "success";
            case false:
                return "failure";
            case null:
                return "n/a"
            default:
                console.log("unhandled reasoner label: " + raw)
                return raw;
        }

}



// for foundryPieChart
    var foundryValue = ndx.dimension(function (d) {
        return foundryLabel(d.foundry);
    });
    var foundryValueGroup = foundryValue.group();

foundryPieChart.width(350)
        .height(200)
        .transitionDuration(1500)
        .dimension(foundryValue)
        .group(foundryValueGroup)
        .radius(90)
        .innerRadius(40)
        .minAngleForLabel(0)
        .label(function(d) { return ''; })
        .legend(dc.legend());

foundryPieChart.on('pretransition', function(chart) {
          chart.selectAll('.dc-legend-item text')
              .text('')
            .append('tspan')
              .text(function(d) { return d.name; })
            .append('tspan')
              .attr('x', 85)
              .attr('text-anchor', 'end')
              .text(function(d) { return d.data; });
      });
      foundryPieChart.render();

// for dloadPieChart
    var dloadValue = ndx.dimension(function (d) {
        return downloadLabel(d.dload);
    });
    var dloadValueGroup = dloadValue.group();

dloadPieChart.width(350)
        .height(200)
        .transitionDuration(1500)
        .dimension(dloadValue)
        .group(dloadValueGroup)
        .radius(90)
        .innerRadius(40)
        .minAngleForLabel(0)
        .label(function(d) { return ''; })
        .legend(dc.legend());

dloadPieChart.on('pretransition', function(chart) {
          chart.selectAll('.dc-legend-item text')
              .text('')
            .append('tspan')
              .text(function(d) { return d.name; })
            .append('tspan')
              .attr('x', 110)
              .attr('text-anchor', 'end')
              .text(function(d) { return d.data; });
      });
      dloadPieChart.render();


// for importsPieChart
    var importsValue = ndx.dimension(function (d) {
        return importsLabel(d.flat);
    });
    var importsValueGroup = importsValue.group();

importsPieChart.width(350)
        .height(200)
        .transitionDuration(1500)
        .dimension(importsValue)
        .group(importsValueGroup)
        .radius(90)
        .innerRadius(40)
        .minAngleForLabel(0)
        .label(function(d) { return ''; })
        .legend(dc.legend());

importsPieChart.on('pretransition', function(chart) {
          chart.selectAll('.dc-legend-item text')
              .text('')
            .append('tspan')
              .text(function(d) { return d.name; })
            .append('tspan')
              .attr('x', 100)
              .attr('text-anchor', 'end')
              .text(function(d) { return d.data; });
      });
      importsPieChart.render();

// for elkPieChart
    var elkValue = ndx.dimension(function (d) {
        return reasonerLabel(d.elk, d.elk_incoherent_count);
    });
    var elkValueGroup = elkValue.group();

elkPieChart.width(350)
        .height(200)
        .transitionDuration(1500)
        .dimension(elkValue)
        .group(elkValueGroup)
        .radius(90)
        .innerRadius(40)
        .minAngleForLabel(0)
//        .externalLabels(10)
//        .externalRadiusPadding(10)
//        .drawPaths(true)
        .label(function(d) { return ''; })
        .legend(dc.legend());

elkPieChart.on('pretransition', function(chart) {
          chart.selectAll('.dc-legend-item text')
              .text('')
            .append('tspan')
              .text(function(d) { return d.name; })
            .append('tspan')
              .attr('x', 85)
              .attr('text-anchor', 'end')
              .text(function(d) { return d.data; });
      });
      elkPieChart.render();


// for hermitPieChart
    var hermitValue = ndx.dimension(function (d) {
        return reasonerLabel(d.hermit, d.hermit_incoherent_count);
    });
    var hermitValueGroup = hermitValue.group();

hermitPieChart.width(350)
        .height(200)
        .transitionDuration(1500)
        .dimension(hermitValue)
        .group(hermitValueGroup)
        .radius(90)
        .innerRadius(40)
        .minAngleForLabel(0)
        .label(function(d) { return ''; })
        .legend(dc.legend());

hermitPieChart.on('pretransition', function(chart) {
          chart.selectAll('.dc-legend-item text')
              .text('')
            .append('tspan')
              .text(function(d) { return d.name; })
            .append('tspan')
              .attr('x', 100)
              .attr('text-anchor', 'end')
              .text(function(d) { return d.data; });
      });
      hermitPieChart.render();


// for cyclePieChart
    var cycleValue = ndx.dimension(function (d) {
        return hasCycleLabel(d.cycles)
    });
    var cycleValueGroup = cycleValue.group();

cyclePieChart.width(350)
        .height(200)
        .transitionDuration(1500)
        .dimension(cycleValue)
        .group(cycleValueGroup)
        .radius(90)
        .innerRadius(40)
        .minAngleForLabel(0)
        .label(function(d) { return ''; })
        .legend(dc.legend());

cyclePieChart.on('pretransition', function(chart) {
          chart.selectAll('.dc-legend-item text')
              .text('')
            .append('tspan')
              .text(function(d) { return d.name; })
            .append('tspan')
              .attr('x', 85)
              .attr('text-anchor', 'end')
              .text(function(d) { return d.data; });
      });
      cyclePieChart.render();

// for cycles bar chart
// compute the max for the x-axis
var maxCycleCount = d3.max(ont_data, function (d) {
    return d.cycle_count;
});

    var cycleCountValue = ndx.dimension(function (d) {
        return (d.cycle_count==0) ? 0.1 : d.cycle_count * 1.0;

    });
    var cycleCountValueGroup = cycleCountValue.group();


cycleCountBarChart.width(350)
            .height(200)
            .dimension(cycleCountValue)
            .group(cycleCountValueGroup)
            .transitionDuration(1500)
            .centerBar(true)
            .x(d3.scale.log().nice().domain([1, maxCycleCount+2]))
            .elasticY(true)
            .yAxisLabel("frequency")
            .xAxisLabel("cycle count")
            .xUnits(function(){return 20;})
            .xAxis().ticks(5, ",.0f").tickSize(5, 0);


// for elk incoherent bar chart
var maxIncoherentCount = d3.max(ont_data, function (d) {
    return Math.max(d.elk_incoherent_count, d.hermit_incoherent_count);
});

    var elkIncoherentCountValue = ndx.dimension(function (d) {
        return d.elk_incoherent_count * 1.0;

    });
    var elkIncoherentCountValueGroup = elkIncoherentCountValue.group();


elkIncoherentCountBarChart.width(350)
            .height(200)
            .dimension(elkIncoherentCountValue)
            .group(elkIncoherentCountValueGroup)
            .transitionDuration(1500)
            .centerBar(true)
            .x(d3.scale.log().domain([1, maxIncoherentCount+2]))
            .elasticY(true)
            .yAxisLabel("frequency")
            .xAxisLabel("incoherent class count")
            .xUnits(function(){return 20;})
            .xAxis().ticks(5, ",.0f").tickSize(5, 0);



// for hermit incoherent bar chart
    var hermitIncoherentCountValue = ndx.dimension(function (d) {
        return d.hermit_incoherent_count * 1.0;

    });
    var hermitIncoherentCountValueGroup = hermitIncoherentCountValue.group();


hermitIncoherentCountBarChart.width(350)
            .height(200)
            .dimension(hermitIncoherentCountValue)
            .group(hermitIncoherentCountValueGroup)
            .transitionDuration(1500)
            .centerBar(true)
            .x(d3.scale.log().domain([1, maxIncoherentCount+2]))
            .elasticY(true)
            .yAxisLabel("frequency")
            .xAxisLabel("incoherent class count")
            .xUnits(function(){return 20;})
            .xAxis().ticks(5, ",.0f").tickSize(5, 0);



ontologyCount
        .dimension(ndx)
        .group(all)
        .html({
            some: '<strong>%filter-count</strong> selected out of <strong>%total-count</strong> records' +
                ' | <a href=\'javascript:dc.filterAll(); dc.renderAll();\'>Reset All</a>',
            all: 'All records selected. Please click on the graph to apply filters.'
        });


// For datatable
var tableDimension = ndx.dimension(function (d) { return d.id; });

function getLogUrl(logPath, tableLabel) {
    if (logPath != null) {
        //return '<a href="' + logPath.substring(logPath.indexOf('log')) + '">' + tableLabel + '</a>'
        return '<a href="' + logPath + '">' + tableLabel + '</a>'
    }
    return "n/a"
}

ontologyDataTable.width(800).height(800)
    .dimension(tableDimension)
    .group(function(d) { return "List of all Selected Ontologies"})
    .size(180)
    .columns([
        function(d) { return d.id; },
        function(d) { return getLogUrl(d.dload_log, d.dload); },
        function(d) { return getLogUrl(d.flat_log, importsLabel(d.flat)); },
        function(d) { return getLogUrl(d.elk_log, reasonerLabel(d.elk, d.elk_incoherent_count)); },
        function(d) { return (d.elk_incoherent_count >=0) ? d.elk_incoherent_count : "n/a"; },
        function(d) { return getLogUrl(d.hermit_log, reasonerLabel(d.hermit, d.hermit_incoherent_count)); },
        function(d) { return (d.hermit_incoherent_count >=0) ? d.hermit_incoherent_count : "n/a"; },
        function(d) { return getLogUrl(d.cycles_log, ((d.cycle_count >=0) ? d.cycle_count : "n/a")); },
    ])
    .sortBy(function(d){ return d.id; })
    // (optional) sort order, :default ascending
    .order(d3.ascending);

    dc.renderAll();



});