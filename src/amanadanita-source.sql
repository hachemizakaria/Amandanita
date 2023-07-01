/*
    amandanita v0.2.030

1. da call
2. prepare js call
    1. templateurl or template clob/blob
    2. ? binding variable 
3. js call
    1. ? replace page items with values for binding 
    2. call ajax
        1. generate data from query
            1. bind variable
            2. execute query and return data to js
    3. parse ajax result
    4. merge data into template
    5. download file

     @plugin1 separator
     @plugin2 Nan

     @plugin_attr1      report filename
     @plugin_attr2      report query
     @plugin_attr3      query type (json vs rows)
     @plugin_attr4      NaN
     @plugin_attr5      NaN
     @plugin_attr6      binding source type
        @plugin_attr7   static
        @plugin_attr8   PageItem
        @plugin_attr9   PageItems
     @plugin_attr10     template source type
        @plugin_attr11  'StaticApplicationFiles' templateurl static app files Filename from static files (#APP_FILES#)
        @plugin_attr12  'Database' db blob (select)
        @plugin_attr13  'StaticFileNameFromPageItem' Page Item containing static Application file name
    
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
    p_ptr_values    in apex_t_varchar2, /* 10;20;30;40*/
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
    l_query_val_count := p_ptr_values.count;
    htp.p(l_query_val_count);
    if l_query_ptr_count != l_query_val_count  THEN 
        --raise_application_error(-20000, 'Number of placeholders does not match number of parameter values');
        return '{"error":"Number of placeholders ' || l_query_ptr_count||' does not match number of parameter values '||l_query_val_count||'"}' ;
    end if;

    -- get bind variable names
    for i IN 1..l_query_ptr_count loop
        ptr_name_array(i) := regexp_substr(p_query, '(:[[:alnum:]_]+)', 1, i);
    end loop;
    -- get values into  array
    /*SELECT column_value BULK COLLECT INTO ptr_val_array
        FROM TABLE ( apex_string.split(p_ptr_values, p_separator) );
    */    

    -- Prepare a cursor to select from query 
    l_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(l_cursor, p_query, dbms_sql.native);

    -- bind all 
    for i IN 1..l_query_ptr_count loop
        dbms_sql.bind_variable(l_cursor, ptr_name_array(i), p_ptr_values(i));
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
    apex_javascript.add_library (
        p_name => 'amandanita',
        p_directory => p_plugin.file_prefix,
        p_check_to_add_minified => false
    );

    -- call the javascript function (client side) to do the render and download from browser
    l_result.javascript_function := 'amandanita.render';
    l_result.ajax_identifier := apex_plugin.get_ajax_identifier; 
        
        -- @param1 templateurl
        -- l_result.attribute_01          := apex_escape.html(p_dynamic_action.attribute_01);
        case p_dynamic_action.attribute_10
                when 'StaticApplicationFiles'
                    then l_result.attribute_01  := v('APP_FILES') || p_dynamic_action.attribute_11;
                when 'Database'
                    then l_result.attribute_01  := p_dynamic_action.attribute_12; --TODO Not implemented Yet
                when 'StaticFileNameFromPageItem'
                    then l_result.attribute_01  := v('APP_FILES') || v(p_dynamic_action.attribute_13);
        end case;
        
        -- @param2 report  filename
        l_result.attribute_02          := apex_escape.html(p_dynamic_action.attribute_01);
        
        -- @param3 binding source type
        l_result.attribute_03          := p_dynamic_action.attribute_06;

        -- @param4 binding values
      --            := p_dynamic_action.attribute_06;
        
        -- prepare pageitems for js ajax call
        case  p_dynamic_action.attribute_06 
            when 'static'       
                then l_result.attribute_04 := null;
            
            when 'PageItem'   -- from P1_DEPT           to #P1_DEPT
                then l_result.attribute_04 := '#' || p_dynamic_action.attribute_08;

            when 'PageItems'  -- from P1_DEPT1,P1_DEPT2 to #P1_DEPT1,#P1_DEPT2
                --then l_result.attribute_04 := p_dynamic_action.attribute_09;
                then select listagg('#' || column_value,',') within group (order by 1)
                        into l_result.attribute_04
                     from table(apex_string.split(p_dynamic_action.attribute_09,','))
                     ;
        end case; 

    return l_result;
end amandanita_render;

FUNCTION amandanita_ajax (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_ajax_result AS 

 
    l_ajax_result     apex_plugin.t_dynamic_action_ajax_result;
 
    
    l_clob  clob;
    
    l_da_query     VARCHAR2(4000) := p_dynamic_action.attribute_02;
         
    l_da_values_source VARCHAR2(4000) := p_dynamic_action.attribute_06;
    --l_da_values    VARCHAR2(4000)     ;
    l_da_values         apex_t_varchar2 ;
        --TODO : what if select from item , check substitutions ...... 

begin
    begin
        -- OLD query without binding variable
        -- open l_c for  l_query; 
        -- apex_json.write('rows', l_c); 
        
        -- get values depending on source
        case   l_da_values_source
            when 'static'
                then
                    for c in (select column_value b from table(apex_string.split(p_dynamic_action.attribute_07,';'))) loop
                        apex_string.push(l_da_values, c.b); 
                    end loop;
            when 'PageItem' -- P1_DEPT 
                then
                    for c in (select column_value b from table(apex_string.split(v(p_dynamic_action.attribute_08),';'))) loop
                        apex_string.push(l_da_values, c.b); 
                    end loop;
            when 'PageItems' -- P1_DEPT1,P1_DEPT2
                then 
                    for c in (select v(column_value) b from table(apex_string.split(p_dynamic_action.attribute_09,','))) loop
                        apex_string.push(l_da_values, c.b); 
                    end loop;


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

