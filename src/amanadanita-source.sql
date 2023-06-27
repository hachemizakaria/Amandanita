/*
    amandanita v0.2.028

     @plugin1 NaN
     @plugin2 separator
     @param1 templateurl
     @param2 report query
     
     @param4 NAN
     @param5 report filename
     @param7 binding source
        @param3 static
        @param4 PageItem
        @param6 PageItems
    @param8 template source    

TODO
- use of sys_context('APEX$SESSION' ...
- use APEX_PLUGIN_UTIL.REPLACE_SUBSTITUTIONS
- done : detect parameter from query     
- template from whatever ??
- binding choices
    - done static value
    - done page item
    - done page items
- done : report filename 

*/

function get_data_from_query(
    p_query         in varchar2,
    p_ptr_values    in varchar2, /* 10;20;30;40*/
    p_separator     in varchar2 /* ; */

)   return clob as

    l_clob clob;

    l_query_ptr_count PLS_INTEGER;
    l_query_val_count PLS_INTEGER;

    ptr_name_array    dbms_sql.varchar2_table;
    ptr_val_array     dbms_sql.varchar2_table;

    l_cursor          INTEGER;
    l_ignore          INTEGER;

begin
    -- check bind variable count
    l_query_ptr_count := regexp_count(p_query, '(:[[:alnum:]_]+)');
    SELECT COUNT(*) INTO l_query_val_count FROM TABLE ( apex_string.split(p_ptr_values, p_separator) );
    if l_query_ptr_count != l_query_val_count  THEN 
        --raise_application_error(-20000, 'Number of placeholders does not match number of parameter values');
        return '{"error":"Number of placeholders does not match number of parameter values"}' ;
    end if;

    -- get bind variable names
    for i IN 1..l_query_ptr_count loop
        ptr_name_array(i) := regexp_substr(p_query, '(:[[:alnum:]_]+)', 1, i);
    end loop;
    -- get values into  array
    SELECT column_value BULK COLLECT INTO ptr_val_array
        FROM TABLE ( apex_string.split(p_ptr_values, p_separator) );

    -- Prepare a cursor to select from query 
    l_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(l_cursor, p_query, dbms_sql.native);

    -- bind all 
    for i IN 1..l_query_ptr_count loop
        dbms_sql.bind_variable(l_cursor, ptr_name_array(i), ptr_val_array(i));
    end loop;

    -- execute and get the result
    dbms_sql.define_column(l_cursor, 1, l_clob);
    l_ignore := dbms_sql.execute_and_fetch(l_cursor); 
    dbms_sql.column_value(l_cursor, 1, l_clob); 

    -- close the cursor
    dbms_sql.close_cursor(l_cursor);

    return l_clob;
    exception WHEN OTHERS THEN
        IF dbms_sql.is_open(l_cursor) THEN
            dbms_sql.close_cursor(l_cursor);
            return '{"error":"ERROR"}'; -- TODO
        END IF;
end get_data_from_query;

function amandanita_render(
        p_dynamic_action in apex_plugin.t_dynamic_action,
        p_plugin in apex_plugin.t_plugin)
    return apex_plugin.t_dynamic_action_render_result is

    l_result apex_plugin.t_dynamic_action_render_result;

    
    --p_templateurl  VARCHAR2(4000) := p_dynamic_action.attribute_01;
    --p_query           := apex_escape.html(p_dynamic_action.attribute_02);
    -- p_filename result 
    -- @param3 bindings values  
        --l_result.attribute_03          := apex_escape.html(p_dynamic_action.attribute_03);
        -- @param2 filename 
        --l_result.attribute_04          := apex_escape.html(p_dynamic_action.attribute_04);
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
        p_check_to_add_minified => true
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
        -- @param2 report  filename
        l_result.attribute_02          := apex_escape.html(p_dynamic_action.attribute_05);
        
        -- @param3 test multiple items
        l_result.attribute_03          := p_dynamic_action.attribute_06;

        -- @param3 bindings values  
        --l_result.attribute_03          := apex_escape.html(p_dynamic_action.attribute_03);
        -- @param2 filename 
        --l_result.attribute_04          := apex_escape.html(p_dynamic_action.attribute_04);

    return l_result;
end amandanita_render;

FUNCTION amandanita_ajax (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_ajax_result AS 

 
    l_ajax_result     apex_plugin.t_dynamic_action_ajax_result;
 
    
    l_clob  clob;
    
    l_da_query     VARCHAR2(4000) := p_dynamic_action.attribute_02;
         
    l_da_values_source VARCHAR2(4000) := p_dynamic_action.attribute_07;
    l_da_values    VARCHAR2(4000)     := p_dynamic_action.attribute_03;
        --TODO : what if select from item , check substitutions ...... 

begin
    begin
        -- OLD query without binding variable
        -- open l_c for  l_query; 
        -- apex_json.write('rows', l_c); 
        
        -- get values depending on source
         case 
            when l_da_values_source = 'static'  -- TODO check substitutions ?? ,TODO check with
                then  l_da_values := p_dynamic_action.attribute_03;

            when l_da_values_source = 'PageItem' -- TODO eval point from plsql or client js ($v(p_dynamic_action.attribute_04))
                then  l_da_values := apex_escape.html( v(p_dynamic_action.attribute_04));

            when l_da_values_source = 'PageItems'  
                then 
                    begin
                        select apex_escape.html(listagg(v(column_value),';') within group (order by 1 )) into l_da_values
                            from table (apex_string.split(p_dynamic_action.attribute_06, ','))
                        ;
                        
                    end;

            else null   ;
        end case;


        -- query with binding TODO check and ? convert to json? 
        l_clob := get_data_from_query(
                    p_query         => l_da_query,
                    p_ptr_values    => l_da_values,
                    p_separator     => ';' --TODO to not be confused with internal apex seprator <,> 
                    );

        apex_json.initialize_output(p_http_header => true);
        apex_json.flush;
        apex_json.open_object;
        apex_json.write('rows',l_clob); --Signature 10 
        apex_json.close_object;
    end;
        
    return l_ajax_result;

end amandanita_ajax;

