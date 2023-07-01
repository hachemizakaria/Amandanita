# Oracle APEX Dynamic Action Plugin - Amandanita

Dynamic Action Plugin to Merge data from a query into a docx Template. based on [doxtemplater](https://docxtemplater.com/)

## About

This plugin is client side renderer, it send data to client side where it use docxtemplater to generate the document based on template.

## Enhancement

Based on [AmandaDocxPrinter](https://github.com/aldocano29/AmandaDocxPrinter), the following enhancements were done :

- more secure query handling (data are sent to client side js instead of query it self).
- query parameter witout submit page

## Features

- [x] template from static files
- [x] parameters
- [ ] query type ( json )
- [ ] template 0 from query
- [ ] use 21c/23c server side MLE modules rendering (schema independent plugin) .
- [ ] template from db.

## Demo Application

- The Demo Application is at (https://apex.oracle.com/pls/apex/r/hachemi/amandanita)
- Credentials: demo/password123

## Credit

- Oracle apex team [apex.oracle.com]
- AmandaDocxPrinter [https://github.com/aldocano29/AmandaDocxPrinter]
- DocxTemplater javascript library by Edgar Hipp [https://github.com/open-xml-templating/docxtemplater]
- stefandobre [https://github.com/stefandobre/apex-mle-demo]
- Daniel Hochleitner[https://github.com/Dani3lSun/apex-plugin-templates]
