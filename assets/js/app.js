// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import Alpine from "alpinejs"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
window.Alpine = Alpine;
Alpine.start();

function showError(form, message) {
    function createError() {
        let error = document.createElement("div");
        error.id = "result";
        error.className = "bg-red-100 rounded-full p-4 m-4 w-full shadow-md";
        form.appendChild(error);
        return error;
    }
    let statusError = document.getElementById("result") ?? createError();
    statusError.innerText = message;
}

let loginForm = document.getElementById("login-form");
if(loginForm !== null) {
    loginForm.addEventListener("submit", async (ev) => {
        ev.preventDefault();
        const request = new Request("/api/login", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                username: document.getElementById("login-username").value,
                password: document.getElementById("login-password").value
            })
        });
        showError(loginForm, "Logging in...");
        const response = await fetch(request);
        const json = await response.json();
        if(json.ok) {
            showError(loginForm, "Login success");
            await new Promise((resolve) => {
                setTimeout(() => { resolve() }, 1000);
            }).then(() => {
                window.location.replace("/posts");
            });
        } else {
            showError(loginForm, json.detail);
        }
    })
}

let deleteForm = document.getElementById("delete-form");
if(deleteForm !== null) {
    deleteForm.addEventListener("submit", async (ev) => {
        ev.preventDefault();
        const idx = deleteForm.dataset.idx;
        const request = new Request(`/api/secure/publish/${idx}`,
        {
            method: "DELETE"
        });
        const response = await fetch(request);
        const json = await response.json();
        if(json.ok) {
            await new Promise((resolve) => {
                setTimeout(() => { resolve() }, 1000);
            }).then(() => {
                window.location.replace("/posts/");
            });
        } else {
            showError(editForm, json.detail);
        }
    });
}

let editForm = document.getElementById("edit-form");
if(editForm !== null) {
    editForm.addEventListener("submit", async (ev) => {
        const idx = editForm.dataset.idx;
        ev.preventDefault();
        const request = new Request(`/api/secure/publish/${idx}`,
        {
            method: "POST",
            body: document.getElementById("edit-body").value

        });
        const response = await fetch(request);
        const json = await response.json();
        if(json.ok) {
            await new Promise((resolve) => {
                setTimeout(() => { resolve() }, 1000);
            }).then(() => {
                window.location.replace(`/posts/${idx}`);
            });
        } else {
            showError(editForm, json.detail);
        }
    });
}
