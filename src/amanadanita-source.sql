/*
    amandanita v0.2.023

*/

-- default values separator for binding
const_values_separator constant varchar2(10) := ';' 


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

function get_data_clob(
    p_query in varchar2,
    p_parameters_values in VARCHAR2,
    p_separator in varchar2 default const_values_separator

) is 
/*

    - get count of placeholders in the query
    - get count of values passed from da
    - if notequals then ERROR -- TODO
    - binding fetch
    - return result
*/
    
    -- return value clob to parsed JSON is js
    l_data clob; 

    
    l_rc            sys_refcursor;
    l_dyn_cursor    number;
    l_dummy         pls_integer;
    l_placeholders  apex_t_varchar2;
    l_placeholder_count pls_integer;
    l_array_values      apex_t_varchar2;
BEGIN

    -- get count of placeholder in the query
    -- ??l_placeholders := apex_t_varchar2(); i:= 0;

    -- convert parameters from string to array of values 
    for c_val in (select column_value 
                    from table(apex_string.split(p_parameters_values,p_separator) )
                 ) loop
        i:= i+1;    
        l_array_values.extend();
        l_array_values(i) := c_val.column_value;
    end loop;

    -- bind 
    begin
    l_dyn_cursor := dbms_sql.open_cursor;

    -- count placeholder
    /*for i in 1..9999 loop
        begin
            dbms_sql.bind_variable(l_dyn_cursor, ':' || i, 'x');
            l_placeholder_count := l_placeholder_count + 1;
            exception
                when others then
                exit; -- no more placeholders found
        end;
    end loop;
    */

    SELECT REGEXP_COUNT(p_query, ':[a-zA-Z0-9_]+') INTO l_placeholder_count FROM DUAL;

    
    dbms_sql.parse(l_dyn_cursor,p_query,dbms_sql.native);
    for idx in 1..l_array_values.count loop
        dbms_sql.bind_variable(l_dyn_cursor,)
    end loop;

    l_dummy := dbms_sql.execute(l_dyn_cursor);

    l_rc := dbms_sql.to_refcursor(l_dyn_cursor);
    FETCH l_rc INTO l_data;
    CLOSE l_rc;


    return l_data;
    exception when others then 
        begin --TODO
            apex_json.open_object;
            apex_json.write(sqlerrm);
            apex_json.close_object;
        end; 
    end;
end get_data_clob;