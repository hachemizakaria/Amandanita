/*
  
*/

// Version number
const version = "0.2.018";

// sample data
const datajson = {
  first_name: "John",
  last_name: "Doe",
  phone: "0652455478",
  description: "this is description",
};

// sample template
//const templateurl = apex.env.APP_FILES + "tag-example.docx";

// amandanita.render is called from da action
const amandanita = {
  render: async function () {
    // version info
    console.log(version);

    var da = this;
    apex.debug.log("da.this", da);

    // get templateurl
    var v_templateurl = apex.env.APP_FILES + da.action.attribute01;

    // data json from ajax
    var v_data_json = {};
    var v_AjaxIdentifier = da.action.ajaxIdentifier;

    // APEX Ajax Call should retrun data
    await new Promise(function (resolve, reject) {
      apex.server.plugin(
        v_AjaxIdentifier,
        {
          x01: da.action.attribute01,
        },
        {
          success: function (ajax_result) {
            v_data_json = JSON.parse(ajax_result.rows[0].JSON_DATA);
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
      saveAs(docxOut, "test.docx");
    } catch (error) {
      console.error("Error ! ", error);
    }
  },
};
