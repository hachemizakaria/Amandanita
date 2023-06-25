/*
    amandanita v0.1.019

*/
function amandanita_render(
        p_dynamic_action in apex_plugin.t_dynamic_action,
        p_plugin in apex_plugin.t_plugin)
    return apex_plugin.t_dynamic_action_render_result is

    l_result apex_plugin.t_dynamic_action_render_result;

    --l_rc sys_refcursor;
    --l_data_clob clob;
    --l_attr_01 p_dynamic_action.attribute_01%TYPE := p_dynamic_action.attribute_01;
    --l_templateurl  VARCHAR2(4000) := p_dynamic_action.attribute_01;
begin

    apex_plugin_util.debug_dynamic_action(
        p_plugin => p_plugin,
        p_dynamic_action => p_dynamic_action
    );
 -- needed libraries
    apex_javascript.add_library (
        p_name => 'docxtemplater',
        p_directory => p_plugin.file_prefix,
        p_requirejs_js_expression => 'docxtemplater',
        p_check_to_add_minified => true
    );
    apex_javascript.add_library (
        p_name => 'axios',
        p_directory => p_plugin.file_prefix,
        p_check_to_add_minified => true
    );
    apex_javascript.add_library (
        p_name => 'FileSaver',
        p_directory => p_plugin.file_prefix,
        p_check_to_add_minified => true
    );

    apex_javascript.add_library (
        p_name => 'pizzip',
        p_directory => p_plugin.file_prefix,
     --   p_requirejs_js_expression => 'pizzip',
        p_check_to_add_minified => false
    );
    --#PLUGIN_FILES#pizzip.js
    apex_javascript.add_library (
        p_name => 'amandanita',
        p_directory => p_plugin.file_prefix,
        p_check_to_add_minified => false
    );

    -- call the javascript function (client side) to do the render and download from browser
    l_result.javascript_function := 'amandanita.render';
    l_result.ajax_identifier := apex_plugin.get_ajax_identifier; 
        
        -- @param1 templateurl
        l_result.attribute_01          := apex_escape.html(p_dynamic_action.attribute_01);
        -- @param2 query TODO testonly
        l_result.attribute_02          := apex_escape.html(p_dynamic_action.attribute_02);

    return l_result;
end amandanita_render;

FUNCTION amandanita_ajax (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_ajax_result AS 

 
    l_ajax_result     apex_plugin.t_dynamic_action_ajax_result;
 
    l_c sys_refcursor;
    l_query VARCHAR2(4000) := p_dynamic_action.attribute_02;--TODO : iam not sure how secure is this
     
begin
    begin
        open l_c for  l_query; 
        apex_json.initialize_output(p_http_header => true);
        apex_json.flush;
        apex_json.open_object;
        apex_json.write('rows', l_c);
        apex_json.close_object;
    end;
        
    return l_ajax_result;

end amandanita_ajax;