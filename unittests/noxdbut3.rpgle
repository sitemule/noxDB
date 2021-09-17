**FREE

///
// noxDB : Node location unit tests
//
// This test suite tests the locating of nodes in an object graph.
//
// @author Mihael Schmidt
// @date 2021-09-10
// @project noxDB
///

ctl-opt nomain;


/include assert
/include '../headers/JSONXML.rpgle'
/include 'ifsio.rpginc'


dcl-s json pointer;


dcl-proc test_null_source export;
  dcl-s node pointer;
  
  node = jx_locate(*null : 'id');
  assert(node = *null : 'Call on *null node should return *null.');
end-proc;


dcl-proc test_non_existing export;
  dcl-s node pointer;
  
  node = jx_locate(json : 'not_existing');
  assert(node = *null : 'Non existing location should return *null.');
end-proc;


dcl-proc test_existing export;
  dcl-s node pointer;
  
  node = jx_locate(json : 'region');
  assert(node <> *null : 'Existing location should be non-null.');
  aEqual('Southern Denmark' : jx_getStr(node));
end-proc;


dcl-proc test_key_with_space export;
  dcl-s node pointer;
  
  node = jx_locate(json : 'city charter');
  assert(node <> *null : 'Existing location should be non-null.');
  iEqual(1355 : jx_getInt(node));
end-proc;


dcl-proc test_key_with_slash export;
  dcl-s node pointer;
  
  node = jx_locate(json : 'postalcode/zipcode');
  assert(node <> *null : 'Existing location should be non-null.');
  aEqual('5000-5270' : jx_getStr(node));
end-proc;


dcl-proc test_key_with_escaped_chars export;
  dcl-s node pointer;
  
  node = jx_locate(json : '"area"');
  assert(node <> *null : 'Existing location should be non-null.');
  assert(79.3 = jx_getNum(node) : 'Area node has wrong value. Should be 79.3.');
end-proc;


dcl-proc test_key_with_starting_space export;
  dcl-s node pointer;
  
  node = jx_locate(json : ' website');
  assert(node <> *null : 'Existing location should be non-null.');
  aEqual('www.odense.dk' : jx_getStr(node));
end-proc;


dcl-proc test_key_with_trailing_space export;
  dcl-s node pointer;
  
  node = jx_locate(json : 'timezone ');
  assert(node <> *null : 'Existing location should be non-null.');
  aEqual('UTC+1' : jx_getStr(node));
end-proc;


dcl-proc test_nested_object export;
  dcl-s node pointer;
  
  node = jx_locate(json : '/population/urban/total');
  assert(node <> *null : 'Existing location should be non-null.');
  iEqual(180760 : jx_getInt(node));
end-proc;


dcl-proc test_nested_object_relative export;
  dcl-s node pointer;
  
  node = jx_locate(json : 'population/urban/total');
  assert(node <> *null : 'Existing location should be non-null.');
  iEqual(180760 : jx_getInt(node));
end-proc;


dcl-proc test_nested_object_absolute_from_middle export;
  dcl-s node pointer;
  dcl-s middle pointer;
  
  middle = jx_locate(json : 'population');
  node = jx_locate(middle : '/population/urban/total');
  assert(node <> *null : 'Existing location should be non-null.');
  iEqual(180760 : jx_getInt(node));
end-proc;


dcl-proc test_nested_array export;
  dcl-s node pointer;
  
  node = jx_locate(json : '/temperature/[11]');
  assert(node <> *null : 'Existing location should be non-null.');
  assert(2.5 = jx_getNum(node : 'C') : 'Odense has an average temperature of 2.5 in December.');
end-proc;


dcl-proc test_nested_object_in_array export;
  dcl-s node pointer;
  
  node = jx_locate(json : '/temperature/[11]/C');
  assert(node <> *null : 'Existing location should be non-null.');
  assert(2.5 = jx_getNum(node) : 'Odense has an average temperature of 2.5 in December.');
end-proc;


dcl-proc test_negative_array_index export;
  dcl-s node pointer;
  
  node = jx_locate(json : '/temperature/[-1]');
  assert(node = *null : 'Negative array index should return *null.');
end-proc;


dcl-proc test_non_existing_array_element export;
  dcl-s node pointer;
  
  node = jx_locate(json : '/temperature/[100]');
  assert(node = *null : 'Non existing array element should return *null.');
end-proc;


dcl-proc test_invalid_array_index_chars export;
  dcl-s node pointer;
  
  node = jx_locate(json : '/temperature/[abc]');
  assert(node = *null : 'Non existing array element should return *null.');
end-proc;


dcl-proc test_key_with_non_ascii_chars export;
  dcl-s node pointer;
  
  node = jx_locate(json : 'Møntergården');
  assert(node <> *null : 'Existing location should be non-null.');
  aEqual('Museum' : jx_getStr(node));
end-proc;


dcl-proc test_alternative_element_separator export;
  dcl-s node pointer;
  
  node = jx_locate(json : '.population.urban.total');
  assert(node <> *null : 'Existing location should be non-null.');
  iEqual(180760 : jx_getInt(node));
end-proc;


dcl-proc test_key_with_alternative_element_separator_absolute export;
  dcl-s node pointer;
  
  node = jx_locate(json : '.area.code');
  assert(node <> *null : 'Existing location should be non-null.');
  aEqual('(+45) 6' : jx_getStr(node));
end-proc;


dcl-proc test_key_with_alternative_element_separator_relative export;
  dcl-s node pointer;
  
  node = jx_locate(json : 'area.code');
  assert(node <> *null : 'Existing location should be non-null.');
  aEqual('(+45) 6' : jx_getStr(node));
end-proc;


dcl-proc setupSuite export;
  json = jx_parseString('{-    
    "id" : 3, -
    "name" : "Odense", -
    "phonetics" : "\u006f\u02c0\u00f0\u006e\u0329\u0073\u0259", -
    "country" : "Denmark", -
    "region" : "Southern Denmark", -
    "established" : 988, -
    "city charter" : 1355, -
    "\"area\"" : 79.3, -
    "elevation" : 13, -
    "population" : { -
      "urban" : { -
        "total" : 180760, -
        "male" : 89033, -
        "female" : 91727 -
      }, -
      "municipal" : 204895 -
    }, -
    "timezone " : "UTC+1", -
    "area.code" : "(+45) 6", -
    "postalcode\/zipcode" : "5000-5270", -
    " website" : "www.odense.dk", -
    "temperature" : [ -
      { "C" : 1.0 , "F" : 30.0 }, -
      { "C" : 1.1 , "F" : 30.0 }, -
      { "C" : 3.1 , "F" : 30.0 }, -
      { "C" : 6.6 , "F" : 30.0 }, -
      { "C" : 11.6 , "F" : 30.0 }, -
      { "C" : 14.7 , "F" : 30.0 }, -
      { "C" : 16.6 , "F" : 30.0 }, -
      { "C" : 16.5 , "F" : 30.0 }, -
      { "C" : 13.0 , "F" : 30.0 }, -
      { "C" : 9.2 , "F" : 30.0 }, -
      { "C" : 5.1 , "F" : 30.0 }, -
      { "C" : 2.5 , "F" : 30.0 } -
    ], -
    "\u004d\u00f8\u006e\u0074\u0065\u0072\u0067\u00e5\u0072\u0064\u0065\u006e" : "Museum" -
  }');
end-proc;


dcl-proc teardownSuite;
  jx_close(json);
end-proc;