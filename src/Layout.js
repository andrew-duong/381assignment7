import { useEffect, useRef, useState } from "react";
import { Outlet, useNavigate, Link } from "react-router-dom";
import NoteList from "./NoteList";
import { v4 as uuidv4 } from "uuid";
import { currentDate } from "./utils";
import { GoogleLogin, useGoogleLogout } from 'react-google-login';
import { gapi } from "gapi-script"

function Layout() {
  const clientId = "912225665519-6rb5ad2hagaiobp5di13kf544ipvffc0.apps.googleusercontent.com";
  const navigate = useNavigate();
  const mainContainerRef = useRef(null);
  const [collapse, setCollapse] = useState(false);
  const [notes, setNotes] = useState([]);
  const [editMode, setEditMode] = useState(false);
  const [currentNote, setCurrentNote] = useState(-1);
  const [user, setUser] = useState(false);
  const [userEmail, setUserEmail] = useState(null);
  const [access, setAccess] = useState(null);

  useEffect(() => {
    const height = mainContainerRef.current.offsetHeight;
    mainContainerRef.current.style.maxHeight = `${height}px`;
    getNote();
  }, [user]);

  useEffect(() => {
    if (currentNote < 0) {
      return;
    }
    if (!editMode) {
      navigate(`/notes/${currentNote + 1}`);
      return;
    }
    navigate(`/notes/${currentNote + 1}/edit`);
  }, [notes]);

  useEffect(()=>{
    function start() {
      gapi.client.init({
        clientId: clientId,
        scope: "",
      })
    };

    gapi.load('client:auth2', start)
  })


  const getNote = async () =>{
    if(user){
    const res = await fetch(`https://ajgghnv3ohvptym7d65emct54m0mznso.lambda-url.us-east-1.on.aws/?email=${userEmail}&access=${access}`,{
      method: "GET",
      headers:{
        "Content-Type": "application/json"
      },
    });
    const data = await res.json();
    setNotes(data);
  }
  }

  function handleCallbackResponse(response){
    var userObject = response.profileObj;
    let { email } = userObject;
    setUserEmail(email);
    setUser(userObject);
    var sign = document.getElementById("signIn");
    sign.classList.toggle('closed');
    setAccess(response.tokenId);
  }
  
  const { signOut } = useGoogleLogout({
    clientId,
    scope:"",
    onLogoutSuccess: () => {
      setUser(false);
      setUserEmail();
      setNotes([]);
      var sign = document.getElementById("signIn");
      sign.classList.toggle("closed");
      setAccess(null);
    },
  });

  function handleSignOut(event) {
    signOut();
  }

  const onSuccess = (res) => {
    handleCallbackResponse(res)
    console.log("Login Successful, Current user: ", res.profileObj)
  }

  const onFailure = (res) => {
    console.log("Login Failed, res: ", res)
  }

  const saveNote = async (note, index) => {
    note.body = note.body.replaceAll("<p><br></p>", "");
    setNotes([
      ...notes.slice(0, index),
      { ...note },
      ...notes.slice(index + 1),
    ]);
    setCurrentNote(index);
    setEditMode(false);
    const res = await fetch(`https://ov2tsp5snwxsgtij254nhry45y0mlcde.lambda-url.us-east-1.on.aws/?email=${userEmail}&access=${access}`,{
      method: "POST",
      headers:{
        "Content-Type": "application/json"
      },
      body: JSON.stringify({note}),
    });
  };

  const deleteNote = async (index, id) => {
    setNotes([...notes.slice(0, index), ...notes.slice(index + 1)]);
    setCurrentNote(0);
    setEditMode(false);
    const res = await fetch(`https://xcslyln53jruge2hatrk3eg3ja0jicfs.lambda-url.us-east-1.on.aws/?id=${id}&email=${userEmail}&access=${access}`,{
      method: "DELETE",
      headers:{
        "Content-Type": "application/json"
      }
    });
  };

  const addNote = async () => {
    const newNote = {
      id: uuidv4(),
      title: "Untitled",
      body: "",
      when: currentDate(),
    }
    
    setNotes([newNote, ...notes]);
    setEditMode(true);
    setCurrentNote(0);
  };

  return (
    <div id="container">
      <header>
        <aside>
          <button id="menu-button" onClick={() => setCollapse(!collapse)}>
            &#9776;
          </button>
        </aside>
        <div id="app-header">
          <h1>
            <Link to="/notes">Lotion</Link>
          </h1>
          <h6 id="app-moto">Like Notion, but worse.</h6>
        </div>
        <div id="verbatim"> {userEmail} </div>
        {Object.keys(user).length !== 0 && 
          ( <button id="signOut" onClick={(e) => handleSignOut(e)}>
          (Log Out)
        </button>)}
        <aside>&nbsp;</aside>
      </header>
      <div id = "signIn">
      <GoogleLogin
      scope = ""
      clientId = {clientId}
      onSuccess = {onSuccess}
      onFailure = {onFailure}
      cookiePolicy = {'single_host_origin'}
      isSignedIn = {true}>
      </GoogleLogin>
    </div>
      {user && (
        <div id="main-container" ref={mainContainerRef}>
          <aside id="sidebar" className={collapse ? "hidden" : null}>
            <header>
              <div id="notes-list-heading">
                <h2>Notes</h2>
                <button id="new-note-button" onClick={addNote}>
                  +
                </button>
              </div>
            </header>
            <div id="notes-holder">
              <NoteList notes={notes} />
            </div>
          </aside>
          <div id="write-box">
            <Outlet context={[notes, saveNote, deleteNote]} />
          </div>
        </div>
      )}
      {!user && (
        <div id="main-container" ref={mainContainerRef}>
          {" "}
        </div>
      )}
    </div>
  );
}

export default Layout;
