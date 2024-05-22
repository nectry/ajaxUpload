type handle = int
val show_handle = _

sequence handles

sequence clientIds

table scratch : { Handle : handle,
                  Filename : option string,
                  MimeType : string,
                  Content : blob,
                  Created : time }
  PRIMARY KEY Handle

datatype status = Ready | Successful of handle | Error

table channels : {
  ClientId : int,
  Created : time,
  Channel : channel status
} PRIMARY KEY ClientId

(* Clean up files that go unclaimed for 30 minutes. *)
task periodic 900 = fn () =>
    tm <- now;
    dml (DELETE FROM scratch
         WHERE Created < {[addSeconds tm (-(30 * 60))]})

(* Clean up clients that have been active for 16 hours. *)
task periodic 3600 = fn () =>
    tm <- now;
    dml (DELETE FROM channels
         WHERE Created < {[addSeconds tm (-(16 * 60 * 60))]})

datatype claim_result =
         NotFound
       | Found of { Filename : option string,
                    MimeType : string,
                    Content : blob }

fun claim h =
    ro <- oneOrNoRows1 (SELECT scratch.Filename, scratch.MimeType, scratch.Content
                        FROM scratch
                        WHERE scratch.Handle = {[h]});
    case ro of
        None => return NotFound
      | Some r =>
        dml (DELETE FROM scratch
             WHERE Handle = {[h]});
        return (Found r)

fun peek h =
    ro <- oneOrNoRows1 (SELECT scratch.Filename, scratch.MimeType, scratch.Content
                        FROM scratch
                        WHERE scratch.Handle = {[h]});
    return (case ro of
                None => NotFound
              | Some r => Found r)


fun getNewClientId () =
  clientId <- nextval clientIds;
  ch <- channel;
  dml (INSERT INTO channels (ClientId, Created, Channel)
    VALUES ({[clientId]}, CURRENT_TIMESTAMP, {[ch]}));
  return (ch, clientId)

fun render {SubmitLabel = sl, OnBegin = ob, OnSuccess = os, OnError = oe} =
    iframeId <- fresh;
    submitId <- fresh;
    (* statusS <- source Ready; *)
    (ch, clientId) <- rpc (getNewClientId ());
    let
        fun loop () =
            msg <- recv ch;
            (case msg of
                Error => oe
              | Successful h => os h
              | Ready => return ());
            loop ()
        fun uploadAction r =
          cho <- oneOrNoRowsE1 (SELECT (channels.Channel)
                                FROM channels
                                WHERE channels.ClientId = {[clientId]});
          case cho of
            None => return <xml><body><active code={error <xml>Please refresh your page to continue</xml>}/></body></xml>
          | Some ch =>
            if Option.isNone (checkMime (fileMimeType r.File)) then
                (* set statusS Error; *)
                send ch Error;
                return <xml></xml>
            else
                h <- nextval handles;
                sqlFilename <- return (case fileName r.File of
                  None => (SQL NULL) | Some fname => (SQL {[Some fname]}));
                dml (INSERT INTO scratch (Handle, Filename, MimeType, Content, Created)
                  VALUES ({[h]}, {sqlFilename}, {[fileMimeType r.File]}, {[fileData r.File]}, CURRENT_TIMESTAMP));
                (* set statusS (Successful h); *)
                send ch (Successful h);
                return <xml></xml>
    in
        spawn (loop ());
        return <xml>
          <form>
            <upload{#File}/>
            <submit value={Option.get "" sl} action={uploadAction} id={submitId} />
          </form>
          (* <dyn signal={
            status <- signal statusS;
            return (case status of
                Error => <xml><active code={oe; return <xml/>}/></xml>
              | Successful h => <xml><active code={os h; return <xml/>}/></xml>
              | Ready => <xml/>)
          }/> *)
          {AjaxUploadFfi.tweakForm (Option.isNone sl) iframeId submitId}
        </xml>
    end
