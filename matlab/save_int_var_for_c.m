function save_int_var_for_c(a, type_and_name, filename, access_mode)
  fid = fopen(filename, access_mode);
  if fid == -1
    disp(['save_var_for_c: fopen' filename ' failed!']);
    return;
  end
  
  fprintf(fid, [type_and_name, '[%d] = {'], length(a) );
  for i = 1 : length(a)
    if mod(i-1, 24) == 0
      fprintf(fid, '\n');
    end
    fprintf(fid, '%d, ', a(i));
  end
  fprintf(fid, '};\n\n');
  
  fclose(fid);
  