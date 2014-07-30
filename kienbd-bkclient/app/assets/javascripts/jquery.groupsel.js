
/*
   --------------------------------
   Dynamic Select Group
   --------------------------------
*/

jQuery.fn.extend({
  groupSelect: function(options,sel_hash) {
    sel_hash = {"opt1": {1 : "sub_opt1.1",2 : "sub_opt1.2"},"opt2" : {1 : "sub_opt2.1",2 : "sup_opt2.2"}}
    switch(options) {
      case undefined :
        case "init" : _init_groupSel(this);break;
      case "create" : {
        if(typeof sel_hash == "object")
          _create_groupSel(this,sel_hash);
        else
          console.log("Wrong arrgument");
        break;
      }
    }
    function _init_groupSel(e) {
      var $that = $(e);

      console.log($that);

      $that.find("select.gps_choice").change(function() {
        var sel = $(this).val();
        console.log(sel);

        if ($(this).val() == "") return false;

        $that.find("select.gps_subChoice").removeAttr("disabled");

        $that.find('select.gps_subChoice > option').each(function() {

          if($(this).attr("alt") != sel) {
            $(this).wrap('<span>').hide().toggleClass("show");
          }

        });

        $that.find('select.gps_subChoice > span > option').each(function() {

          if ($(this).attr("alt") == sel) {
            $(this).unwrap("span").show().toggleClass("show");
          }
        });
        val = $that.find("select.gps_subChoice option.show").first().val();
        $that.find("select.gps_subChoice").val(val);
      });
      $that.find("select.gps_choice").change();
    }


    function _create_groupSel(e,sel_hash) {
      $that = $(e);
      $that.html();
    }
  }
})


