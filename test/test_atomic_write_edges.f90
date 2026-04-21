program test_atomic_write_edges
  use fgof_temp, only : &
    FGOF_TEMP_ERR_CREATE_FAILED, &
    FGOF_TEMP_ERR_INVALID_OPTIONS, &
    FGOF_TEMP_ERR_REPLACE_FAILED, &
    atomic_write, &
    replace_file
  use fgof_temp_types, only : write_result
  implicit none

  type(write_result) :: result_value

  result_value = atomic_write("", "text")
  if (result_value%error_code /= FGOF_TEMP_ERR_INVALID_OPTIONS) error stop "atomic write should reject empty targets"

  result_value = atomic_write("/tmp/", "text")
  if (result_value%error_code /= FGOF_TEMP_ERR_INVALID_OPTIONS) error stop "atomic write should reject directory-like targets"

  result_value = atomic_write("/definitely/not/here/config.txt", "text")
  if (result_value%error_code /= FGOF_TEMP_ERR_CREATE_FAILED) error stop "atomic write should report create failure when parent is missing"

  result_value = replace_file("/tmp/fgof-temp-missing-source", "/definitely/not/here/output.txt")
  if (result_value%error_code /= FGOF_TEMP_ERR_INVALID_OPTIONS) error stop "replace_file should reject missing source paths before rename"

  result_value = replace_file("/tmp/fgof-temp-missing-source", "output.txt")
  if (result_value%error_code /= FGOF_TEMP_ERR_INVALID_OPTIONS) error stop "replace_file should still reject missing source paths for relative destinations"
end program test_atomic_write_edges
