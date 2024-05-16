(** A simple widget for uploading files to the server without reloading the current page *)

type handle
(* Unique ID for a file that has been uploaded *)

(* HACK: Exposing this is not ideal, but it's pretty convenient. It's critical that `read` is not exposed. *)
val show_handle : show handle

datatype claim_result =
         NotFound (* That file was either claimed by someone else or was uploaded too long ago and never claimed. *)
       | Found of { Filename : option string,
                    MimeType : string,
                    Content : blob }

val claim : handle -> transaction claim_result
(* In server-side code, claim ownership of a [handle]'s contents, deleting the persistent record of the file data. *)

val peek : handle -> transaction claim_result
(* Like [claim], but keeps the file in temporary storage.  Beware that files older than 30 minutes may be removed automatically! *)

val render : {SubmitLabel : option string,
              (* Text for submit button, or [None] to auto-submit when selected file changes *)
              OnBegin : transaction {},
              (* Run this when an upload begins. *)
              OnSuccess : handle -> transaction {},
              (* Run this after a successful upload. *)
              OnError : transaction {}
              (* Run this when upload fails (probably because of an unsupported MIME type). *)}
             -> transaction xbody
(* Produce HTML for a file upload control *)
