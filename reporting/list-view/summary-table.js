

function getCheckMinusImg(data, type, row, meta) {
    var log_type;
    switch (meta.col) {
    case 1:
        log_type = 'dload';
        break;
    case 2:
        log_type = 'flat';
        break;
    case 3:
        log_type = 'elk';
        break;
    default:
        console.log('Unhandled column for generating links to the log.')
    }

    var log_url = 'data/log/' + row.id + '_' + log_type + '.log';
    if (data == null) {
        return '<center><img width="40" src="images/na-icon.svg"><center>'
    }
    if (data) {
        return '<center><a href="'+ log_url +'"><img width="40" src="images/ok-icon.svg"></a></center>'
    } else {
        return '<center><a href="'+ log_url +'"><img width="40" src="images/fail-icon.svg"></a></center>'
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

               if ($.fn.dataTable.isDataTable('#example')) {
                   table = $('#example').DataTable();

                   // check to see if there is already a row with the same id
                   var rows = table.rows(function (idx, data, node) {
                                     return data.id  == json[0].id ? true : false;
                                 }).data();
                   if (rows.length != 0) {
                        var row = rows[0];
                        for (var key in json[0]) {
                             if (key != 'id' && json[0][key] != null) {
                                row[key] = json[0][key];
                             }
                        }
                        table.rows().invalidate().draw();
                   } else {
                        table.rows.add(json).draw();
                   }
               } else {
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