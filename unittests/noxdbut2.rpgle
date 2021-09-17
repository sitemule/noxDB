**FREE

///
// noxDB : JSON serializer unit tests
//
// This test suite tests the noxDB JSON serializer. The JSON objects will be built
// using the noxDB API. The resulting test data is in the folder data/serializer 
// (files test*.json).
//
// @author Mihael Schmidt
// @date 2021-09-10
// @project noxDB
///

ctl-opt nomain;


/include assert
/include '../headers/JSONXML.rpgle'
/include 'ifsio.rpginc'


dcl-proc test_empty_object export;
  dcl-s json pointer;
  
  json = jx_newObject();
  
  compare(json : 'test1-empty-object.json');
end-proc;


dcl-proc test_flat_object export;
  dcl-s json pointer;
  
  json = jx_newObject();
  jx_setStr(json : 'project' : 'noxDB');
  jx_setInt(json : 'code_lines' : 9356);
  jx_setBool(json : 'active' : *on);
  jx_setNull(json : 'bugs');
  jx_setNum(json : 'code_coverage' : 99.999);
  
  compare(json : 'test2-flat-object.json');
end-proc;


dcl-proc test_date_time export;
  dcl-s json pointer;
  
  json = jx_newObject();
  jx_setDate(json : 'date' : d'2021-09-10');
  jx_setTime(json : 'time' : t'11.12.13');
  jx_setTimestamp(json : 'timestamp' : z'2021-09-10-11.12.13.000000');
  
  compare(json : 'test3-date-time.json');
end-proc;


dcl-proc test_nested_object export;
  dcl-s json pointer;
  dcl-s nested pointer;
  
  json = jx_newObject();
  nested = jx_locateOrCreate(json : 'project');
  jx_setStr(nested : 'name' : 'noxDB');
  
  compare(json : 'test4-nested-object.json');
end-proc;


dcl-proc test_umlaute export;
  dcl-s json pointer;
  
  json = jx_newObject();
  jx_setStr(json : 'umlaute' : 'Umlaute äöüÄÖÜ');
  
  compare(json : 'test5-umlaute.json');
end-proc;


dcl-proc test_escaped_special_chars export;
  dcl-s json pointer;
  
  json = jx_newObject();
  jx_setStr(json : 'chars' : '\ / "');
  
  compare(json : 'test6-escaped-special-chars.json');
end-proc;


dcl-proc test_empty_array export;
  dcl-s json pointer;
  
  json = jx_newArray();
  
  compare(json : 'test7-empty-array.json');
end-proc;


dcl-proc test_mixed_array_elements export;
  dcl-s json pointer;
  
  json = jx_newArray();
  jx_setInt(json : '[0]' : 1);
  jx_setNum(json : '[1]' : 1234.5678);
  jx_setStr(json : '[2]' : 'noxDB');
  jx_setDate(json : '[3]' : d'2020-09-10');
  jx_setBool(json : '[4]' : *on);
  jx_setBool(json : '[5]' : *off);
  jx_setNull(json : '[6]');
  
  compare(json : 'test8-mixed-array-elements.json');
end-proc;


dcl-proc test_array_push_ubound export;
  dcl-s json pointer;
  
  json = jx_newArray();
  jx_setInt(json : '[UBOUND]' : 1);
  jx_setNum(json : '[UBOUND]' : 1234.5678);
  
  compare(json : 'test9-array-push-ubound.json');
end-proc;


dcl-proc test_nested_array export;
  dcl-s json pointer;
  dcl-s nested pointer;
  
  json = jx_newArray();
  nested = jx_arrayPush(json : jx_newArray());
  jx_setInt(nested : '[0]' : 1);
  jx_setInt(nested : '[1]' : 2);
  jx_setInt(nested : '[2]' : 3);
  jx_setInt(nested : '[3]' : 4);
  nested = jx_arrayPush(json : jx_newArray());
  jx_setInt(nested : '[0]' : 5);
  jx_setInt(nested : '[1]' : 6);
  jx_setInt(nested : '[2]' : 7);
  jx_setInt(nested : '[3]' : 8);
  
  compare(json : 'test10-nested-array.json');
end-proc;


dcl-proc test_mixed_nested_objects_arrays export;
  dcl-s json pointer;
  dcl-s nested pointer;
  
  json = jx_newArray();
  nested = jx_arrayPush(json : jx_newObject());
  nested = jx_moveObjectInto(nested : 'values' : jx_newArray());
  jx_setInt(nested : '[0]' : 1);
  jx_setInt(nested : '[1]' : 2);
  jx_setInt(nested : '[2]' : 3);
  jx_setInt(nested : '[3]' : 4);
  nested = jx_arrayPush(json : jx_newObject());
  nested = jx_moveObjectInto(nested : 'values' : jx_newArray());
  jx_setInt(nested : '[0]' : 5);
  jx_setInt(nested : '[1]' : 6);
  jx_setInt(nested : '[2]' : 7);
  jx_setInt(nested : '[3]' : 8);
  
  compare(json : 'test11-mixed-nested-objects-arrays.json');
end-proc;


dcl-proc compare;
  dcl-pi *n;
    json pointer;
    filename char(1000) const;
  end-pi;
  
  dcl-s data varchar(10000);
  dcl-s resultData varchar(10000);
  
  data = jx_asJsonText(json);
  resultData = loadTestData(filename);
  
  aEqual(resultData : data : 'Serialized JSON does not match expected result data. ' + %trim(filename));
  
  on-exit;
    jx_close(json);
end-proc;


dcl-proc loadTestData;
  dcl-pi *n varchar(10000);
    pFilename char(1000) const;
  end-pi;
  
  dcl-s filename char(1001);
  dcl-s fd int(10);
  dcl-s len int(10) inz(1);
  dcl-s buffer char(10000);
  dcl-s d char(50);
  
  filename = 'unittests/data/serializer/' + %trim(pFilename) + x'00';
  fd = open(%addr(filename) : O_RDONLY + O_TEXTDATA);
  if (fd >= 0);
    len = read(fd : %addr(buffer) : %size(buffer));
    return %subst(buffer : 1 : len);
  endif;
  
  return *blank;
  
  on-exit;
    callp close(fd);
end-proc;