/*
  
    -- @param1 templateurl      l_result.attribute_01         
    -- @param2 report  filename l_result.attribute_02          

    -- NIY@param3 type binding     l_result.attribute_03 
    -- @param4 Pageitem to send    l_result.attribute_04 


*/

// Version number
const version = "0.2.031";

// amandanita.render is called from da action
const amandanita = {
  render: async function () {
    // version info
    console.log(version);

    var da = this;
    apex.debug.log("da.this", da);

    // get templateurl

    var v_templateurl = da.action.attribute01;

    // TODO test
    console.log(da.action.attribute04);

    // data json from ajax
    var v_data_json = {};
    var v_AjaxIdentifier = da.action.ajaxIdentifier;

    // APEX Ajax Call should retrun data
    await new Promise(function (resolve, reject) {
      apex.server.plugin(
        v_AjaxIdentifier,
        {
          x01: "test",  // string
          pageItems: da.action.attribute04, //"#P1_DEPT1,#P1_DEPT2" 
        },
        {
          success: function (ajax_result) {
            v_data_json = JSON.parse(ajax_result.rows);

            resolve(); // Resolve the promise when the AJAX call is successful
          },
          error: function (xhr, status, message) {
            console.log(message);

            reject(new Error(message));
            // Reject the promise if there is an error
          },
        }
      );
    });

    try {
      // get template content from templateurl
      const response = await axios.get(v_templateurl, {
        responseType: "arraybuffer",
      });

      // load template
      const zip = new PizZip(response.data);
      const doc = new Docxtemplater();
      doc.loadZip(zip);

      // replace placeholders
      doc.setData(v_data_json);
      doc.render();

      // generate the result document
      const docxOut = doc.getZip().generate({
        type: "blob",
        mimeType:
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      });

      // allow downloading the final report
      var v_report_name = da.action.attribute02;
      saveAs(docxOut, v_report_name || "test.docx");
    } catch (error) {
      console.error("Error ! ", error);
    }
  },
};
