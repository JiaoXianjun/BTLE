function save_int_var_for_c_2d(a, type_and_name, filename, access_mode)
  fid = fopen(filename, access_mode);
  if fid == -1
    disp(['save_int_var_for_c_2d: fopen' filename ' failed!']);
    return;
  end
  
  [num_row, num_col] = size(a);
  
  fprintf(fid, [type_and_name, '[%d][%d] = {'], num_row, num_col );
  for j = 1 : num_row
      fprintf(fid, '\n{');
      for i = 1 : num_col
        fprintf(fid, '%d, ', a(j,i));
      end
      fprintf(fid, '},');
  end
  
  fprintf(fid, '\n};\n\n');
  
  fclose(fid);
  