#include <ctype.h>

#include <ajaxUpload.h>

uw_Basis_string uw_AjaxUploadFfi_notifySuccess(uw_context ctx, uw_Basis_string submitId, uw_Basis_int handle) {
  uw_Basis_string r = uw_Basis_mstrcat(ctx,
                          "<script type=\"text/javascript\">var subm = parent.document.getElementById(\"",
                          submitId,
                          "\"); parent.event = {keyCode : ",
                          uw_Basis_htmlifyInt(ctx, handle),
                          "}; subm.withHandle(); </script>",
                          NULL);
  return r;
}

uw_Basis_string uw_AjaxUploadFfi_notifyError(uw_context ctx, uw_Basis_string submitId) {
  return uw_Basis_mstrcat(ctx,
                          "<script type=\"text/javascript\">var subm = parent.document.getElementById(\"",
                          submitId,
                          "\"); parent.event = {}; subm.withError(); </script>",
                          NULL);
}

uw_Basis_string uw_AjaxUploadFfi_stringToId(uw_context ctx, uw_Basis_string s) {
  char *s2 = s;

  if (s2[0] == 'u' && s2[1] == 'w')
    s2 += 2;

  if (*s2 == '-')
    ++s2;

  for (++s2; *s2; ++s2)
    if (!isdigit(*s2))
      uw_error(ctx, FATAL, "AjaxUploadFfi.stringToId: Invalid ID");

  return s;
}
