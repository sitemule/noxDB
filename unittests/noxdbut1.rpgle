**FREE

///
// noxDB : JSON parser unit tests
//
// This test suite tests the noxDB JSON parser. The test data is in the folder
// data/parser (files test*.json) with the corresponding expected test result (files
// result*.json).
//
// @author Mihael Schmidt
// @date 2021-09-03
// @project noxDB
///

ctl-opt nomain;


/include assert
/include '../headers/JSONXML.rpgle'
/include 'ifsio.rpginc'


dcl-proc test_empty_object export;
  runDataTest('test1-empty-object.json');
end-proc;

dcl-proc test_empty_array export;
  runDataTest('test2-empty-array.json');
end-proc;

dcl-proc test_string_root_node export;
  runDataTest('test3-string-root-node.json');
end-proc;

dcl-proc test_flat_object export;
  runDataTest('test4-flat-object.json');
end-proc;

dcl-proc test_trailing_comma export;
  runDataTest('test5-trailing-comma.json');
end-proc;

dcl-proc test_nested_object export;
  runDataTest('test6-nested-object.json');
end-proc;

dcl-proc test_nested_array export;
  runDataTest('test7-nested-array.json');
end-proc;

dcl-proc test_apos_as_enclosing_chars export;
  runDataTest('test8-apos-as-enclosing-chars.json');
end-proc;

dcl-proc test_mixed_enclosing_string_chars export;
  runDataTest('test9-mixed-enclosing-string-chars.json');
end-proc;

dcl-proc test_escaped_unicode_chars export;
  runDataTest('test10-escaped-unicode-chars.json');
end-proc;

dcl-proc test_escaped_special_chars export;
  runDataTest('test11-escaped-special-chars.json');
end-proc;

dcl-proc test_numbers export;
  runDataTest('test12-numbers.json');
end-proc;

dcl-proc test_whitespace export;
  runDataTest('test13-whitespace.json');
end-proc;

dcl-proc test_number_root_node export;
  runDataTest('test14-number-root-node.json');
end-proc;

dcl-proc test_missing_quote_on_key export;
  runDataTest('test15-missing-quote-on-key.json');
end-proc;

dcl-proc test_missing_quote_on_value export;
  runDataTest('test16-missing-quote-on-value.json');
end-proc;

dcl-proc test_missing_value_separator_in_object export;
  runDataTest('test17-missing-value-separator-in-object.json');
end-proc;

dcl-proc test_missing_value_separator_in_array export;
  runDataTest('test18-missing-value-separator-in-array.json');
end-proc;

dcl-proc test_invalid_escape_sequence export;
  runDataTest('test19-invalid-escape-sequence.json');
end-proc;

dcl-proc test_invalid_unicode_sequence export;
  runDataTest('test20-invalid-unicode-sequence.json');
end-proc;

dcl-proc test_incomplete_unicode_sequence export;
  runDataTest('test21-incomplete-unicode-sequence.json');
end-proc;

dcl-proc test_multiple_decimal_points export;
  runDataTest('test22-multiple-decimal-points.json');
end-proc;

dcl-proc test_invalid_value_unknown export;
  runDataTest('test23-invalid-value-unknown.json');
end-proc;

dcl-proc test_invalid_root_value export;
  runDataTest('test24-invalid-root-value.json');
end-proc;

dcl-proc test_invalid_positive_float export;
  runDataTest('test25-invalid-positive-float.json');
end-proc;


dcl-proc runDataTest;
  dcl-pi *n;
    filename char(1000) const;
  end-pi;
  
  dcl-s data varchar(10000);
  dcl-s resultData varchar(10000);
  dcl-s json pointer;
  
  data = loadTestData(filename);
  resultData = loadResultData(filename);
  
  json = jx_parseString(data);
  if (resultData = 'fail' and jx_error(json));
    // everything is ok as it was intended to fail
  elseif (jx_error(json));
    fail('Could not parse data from test ' + %trimr(filename) + '. Parser error: ' + jx_message());
  elseif (resultData = 'fail');
    fail('Parse should have failed at test ' + %trimr(filename) + '.');
  else;
    data = jx_asJsonText(json);
    aEqual(resultData : data : 'Parsed test data does not match expected result data. ' + %trim(filename));
  endif;
  
  on-exit;
    jx_close(json);
end-proc;


// This does not work because RPGUnit will stop running this procedure on the first failed assert.
// We would need parameterized unit tests for this (open issue at iRPGUNit).
dcl-proc test_dataFiles; //  export;
  dcl-s filenames char(1000) dim(100);
  dcl-s data varchar(10000);
  dcl-s resultData varchar(10000);
  dcl-s i int(10);
  dcl-s json pointer;
  
  filenames = listTestDataFiles();
  
  for i = 1 to %elem(filenames);
    if (filenames(i) = *blank);
      leave;
    endif;
    
    data = loadTestData(filenames(i));
    json = jx_parseString(data);
    if (jx_error(json));
      fail('Could not parse data from test ' + %trimr(filenames(i)) + '. Parser error: ' + jx_message());
    endif;
    
    data = jx_asJsonText(json);
    resultData = loadResultData(filenames(i));
    aEqual(data : resultData : 'Parsed test data does not match expected result data. ' + %trim(filenames(i)));
    
    jx_close(json);
  endfor;
end-proc;


dcl-proc loadResultData;
  dcl-pi *n varchar(10000);
    filename char(1000) const;
  end-pi;
  
  dcl-s testCase char(10);
  
  testCase = %subst(filename : 5 : %scan('-' : filename) - 5);
  return loadTestData('result' + %trim(testCase) + '.json');
end-proc;


dcl-proc listTestDataFiles;
  dcl-pi *n char(1000) dim(100) end-pi;
  
  dcl-s filenames char(1000) dim(100);
  dcl-s dir pointer;
  dcl-ds dirEntry likeds(dirent) based(ptrDirEntry);
  dcl-s i int(10);
  
  dir = opendir('unittests/data/parser');
  if (dir <> *null);
    
    ptrDirEntry = readdir(dir);
    dow (ptrDirEntry <> *null);
      if (%subst(dirEntry.d_name : 1 : 1) <> '.');
        i += 1;
        filenames(i) = %subst(dirEntry.d_name : 1 : dirEntry.d_nameLen);
      endif;
      
      ptrDirEntry = readdir(dir);
    enddo;
    
  else;
    dsply 'No test data files found.';
  endif; 
  
  return filenames;
  
  on-exit;
    closedir(dir);
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
  
  filename = 'unittests/data/parser/' + %trim(pFilename) + x'00';
  fd = open(%addr(filename) : O_RDONLY + O_TEXTDATA);
  if (fd >= 0);
    len = read(fd : %addr(buffer) : %size(buffer));
    return %subst(buffer : 1 : len);
  endif;
  
  return *blank;
  
  on-exit;
    callp close(fd);
end-proc;