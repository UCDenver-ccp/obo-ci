

function getCheckMinusImg(data, type, row) {
    if (data == null) {
        return '<center><img width="40" src="images/na-icon.svg"><center>'
    }
    if (data) {
        return '<center><img width="40" src="images/ok-icon.svg"></center>'
    } else {
        return '<center><img width="40" src="images/fail-icon.svg"></center>'
    }
}

$(document).ready(function() {
    var combined_json = [];
    $.ajax({
      type: 'POST',
      url: 'cgi-bin/jqueryFileTree.pl',
      success: function(data) {
         $(data).find("a:contains(.json)").each(function() {
            var json_filename = 'data/' + this.rel;
            console.log('loading json file: '+ json_filename)

            $.getJSON(json_filename, function(json) {
                combined_json = combined_json.concat(json);
                console.log(combined_json)

               if ($.fn.dataTable.isDataTable('#example')) {
                   console.log("Reloading DataTable with " + JSON.stringify(json))
                   table = $('#example').DataTable();
                   table.rows.add(json).draw();
               } else {
                   console.log("Initializing DataTable with " + JSON.stringify(json))
                   $('#example').DataTable( {
                       data: json,
                       // forcing columns to be of type string below allows the sorting to work properly
                       columns: [
                           { "data": "id" },
                           { "data": "dload", render: getCheckMinusImg, "sType": "string", "aTargets": [ 0 ] },
                           { "data": "flat", render: getCheckMinusImg, "sType": "string", "aTargets": [ 0 ] },
                           { "data": "elk", render: getCheckMinusImg, "sType": "string", "aTargets": [ 0 ] }
                       ]
                   });
               }
            });
         });
      }
    });
});