let imgArray = {};

document.addEventListener("DOMContentLoaded", function () {
  console.log("dom content loaded");
  M.FormSelect.init(document.querySelector("#fps-select"));
  let elems = document.querySelectorAll(".collapsible");
  let instances = M.Collapsible.init(elems);
});

let socket = io();

function is_img_string_equal(imgString1, imgString2) {
  return imgString1.localeCompare(imgString2) ? false : true;
}

function start_capture(path) {
  let currentSourceNumber = document.querySelectorAll("#source-content>*")
    .length;
  socket.emit("start-video", path, String(currentSourceNumber + 1), function (
    cap_tab,
    cap_frame
  ) {
    $("#main-tabs").append(cap_tab);
    $("#source-content").append(cap_frame);
    M.Tabs.init(document.querySelector("#main-tabs"));

    requestAnimationFrame((timestamp) =>
      request_image(path, currentSourceNumber)
    );
  });
}

function start_robot_capture(path) {
  let currentSourceNumber = document.querySelectorAll("#source-content>*")
    .length;
  socket.emit(
    "start-robot-video",
    path,
    String(currentSourceNumber + 1),
    function (
      top_image_tab,
      top_image_frame,
      bottom_image_tab,
      bottom_image_frame
    ) {
      $("#main-tabs").append(top_image_tab);
      $("#source-content").append(top_image_frame);
      $("#main-tabs").append(bottom_image_tab);
      $("#source-content").append(bottom_image_frame);
      M.Tabs.init(document.querySelector("#main-tabs"));

      requestAnimationFrame((timestamp) =>
        request_robot_image(path, currentSourceNumber)
      );
    }
  );
}

function request_image(requestedPath, sourceNumber) {
  setTimeout(function () {
    let functionName = false;
    let selectedIndex = "0";
    try {
      selectedIndex = document.querySelector(
        "li.active input.debug-image-index-selector:checked + span"
      ).innerText;
    } catch (error) {
      //console.log(error)
    }
    try {
      functionName = document.querySelector(
        "#function-selector-div>ul>li.active>div>span"
      ).innerText;
    } catch (error) {
      // console.log(error);
    }

    socket.emit(
      "request-cap-img",
      requestedPath,
      functionName,
      selectedIndex,
      function (
        imgByteString,
        returnedPath, // TODO: Remove returnedPath
        debugImageSize
      ) {
        if (imgByteString === "cap closed") {
          //TODO: Not working
          return;
        }
        if (imgByteString.includes("error")) {
          // console.log(imgByteString);
          // TODO: deal with error
          return;
        }

        if (!(returnedPath in imgArray)) {
          // if source is new
          let videoFeedCanvas = document.getElementById(
            "video-feed-canvas-" + requestedPath
          );
          let context = videoFeedCanvas.getContext("2d");
          imgArray[returnedPath] = new Image();
          imgArray[returnedPath].onload = function () {
            if (
              document.getElementById("tab-" + returnedPath) &&
              document.getElementById("tab-" + returnedPath).children[0]
                .className === "active"
            ) {
              context.drawImage(
                this,
                0,
                0,
                videoFeedCanvas.width,
                videoFeedCanvas.height
              );
            }
          };
        }
        //populate debug image array index selection
        if (functionName) {
          let indexSelectorDiv = document.querySelector(
            "li.active .debug-image-index-div"
          );
          if (indexSelectorDiv && indexSelectorDiv.childElementCount == 0) {
            //if it is the first time
            debugImageSize = parseInt(debugImageSize);
            for (let i = 0; i < debugImageSize; i++) {
              indexSelectorDiv.appendChild(document.createElement("label"));
              indexSelectorDiv.children[i].appendChild(
                document.createElement("input")
              );
              indexSelectorDiv.children[i].children[0].setAttribute(
                "type",
                "radio"
              );
              indexSelectorDiv.children[i].children[0].setAttribute(
                "name",
                functionName + "-debug-index-selector"
              );
              indexSelectorDiv.children[i].children[0].setAttribute(
                "class",
                "debug-image-index-selector with-gap"
              );
              indexSelectorDiv.children[i].appendChild(
                document.createElement("span")
              );
              indexSelectorDiv.children[i].children[1].innerText = i;
            }
          }
        }

        // write new image
        let oldImgString = imgArray[returnedPath].src.replace(
          "data:image/jpeg;base64,",
          ""
        );
        if (
          imgByteString.localeCompare(oldImgString) ||
          !oldImgString.localeCompare("")
        ) {
          // if strings are different or img.src are empty
          imgArray[returnedPath].src =
            "data:image/jpeg;base64," + imgByteString;
        }

        requestAnimationFrame((timestamp) =>
          request_image(requestedPath, sourceNumber)
        );
      }
    );
  }, 1000 / parseInt(document.querySelector("#fps-select").value));
}

function register_new_canvas_image(path) {
  let videoFeedCanvas = document.getElementById("video-feed-canvas-" + path);
  let context = videoFeedCanvas.getContext("2d");
  imgArray[path] = new Image();
  imgArray[path].onload = function () {
    if (
      document.getElementById("tab-" + path) &&
      document.getElementById("tab-" + path).children[0].className === "active"
    ) {
      context.drawImage(
        this,
        0,
        0,
        videoFeedCanvas.width,
        videoFeedCanvas.height
      );
    }
  };
}

function request_robot_image(requestedPath, sourceNumber) {
  setTimeout(function () {
    let functionName = false;
    let selectedIndex = "0";
    try {
      selectedIndex = document.querySelector(
        "li.active input.debug-image-index-selector:checked + span"
      ).innerText;
    } catch (error) {
      //console.log(error)
    }
    try {
      functionName = document.querySelector(
        "#function-selector-div>ul>li.active>div>span"
      ).innerText;
    } catch (error) {
      // console.log(error);
    }

    socket.emit(
      "request-robot-img",
      requestedPath,
      functionName,
      selectedIndex,
      function (
        top_img_byte_string,
        bottom_img_byte_string,
        returnedPath, //TODO: remove path
        debugImageSize
      ) {
        let topImgPath = requestedPath + "-top-image";
        if (!(topImgPath in imgArray)) {
          // if source is new
          register_new_canvas_image(topImgPath);
        }

        let bottomImgPath = requestedPath + "-bottom-image";
        if (!(bottomImgPath in imgArray)) {
          // if source is new
          register_new_canvas_image(bottomImgPath);
        }
        //populate debug image array index selection
        if (functionName) {
          let indexSelectorDiv = document.querySelector(
            "li.active .debug-image-index-div"
          );
          if (indexSelectorDiv && indexSelectorDiv.childElementCount == 0) {
            //if it is the first time
            debugImageSize = parseInt(debugImageSize);
            for (let i = 0; i < debugImageSize; i++) {
              indexSelectorDiv.appendChild(document.createElement("label"));
              indexSelectorDiv.children[i].appendChild(
                document.createElement("input")
              );
              indexSelectorDiv.children[i].children[0].setAttribute(
                "type",
                "radio"
              );
              indexSelectorDiv.children[i].children[0].setAttribute(
                "name",
                functionName + "-debug-index-selector"
              );
              indexSelectorDiv.children[i].children[0].setAttribute(
                "class",
                "debug-image-index-selector with-gap"
              );
              indexSelectorDiv.children[i].appendChild(
                document.createElement("span")
              );
              indexSelectorDiv.children[i].children[1].innerText = i;
            }
          }
        }

        // write new image
        let oldImgString = imgArray[topImgPath].src.replace(
          "data:image/jpeg;base64,",
          ""
        );
        if (
          top_img_byte_string.localeCompare(oldImgString) ||
          !oldImgString.localeCompare("")
        ) {
          // if strings are different or img.src are empty
          imgArray[topImgPath].src =
            "data:image/jpeg;base64," + top_img_byte_string;
        }

        // write new image
        oldImgString = imgArray[bottomImgPath].src.replace(
          "data:image/jpeg;base64,",
          ""
        );
        if (
          bottom_img_byte_string.localeCompare(oldImgString) ||
          !oldImgString.localeCompare("")
        ) {
          // if strings are different or img.src are empty
          imgArray[bottomImgPath].src =
            "data:image/jpeg;base64," + bottom_img_byte_string;
        }

        requestAnimationFrame((timestamp) =>
          request_robot_image(requestedPath, sourceNumber)
        );
      }
    );
  }, 1000 / parseInt(document.querySelector("#fps-select").value));
}

function stop_capture(buttonElement, captureKey, sourceNumber) {
  if (captureKey.startsWith("split-canvas-")) {
    document.getElementById("source-" + sourceNumber).remove();
    document.getElementById("tab-" + captureKey).remove();
    if (document.querySelectorAll("#main-tabs>*").length > 1) {
      M.Tabs.init(document.querySelector("#main-tabs"));
    }
  } else {
    socket.emit("stop-capture", captureKey, function (result) {
      if (result === "success") {
        // let sourceHTMLCollection =
        //   buttonElement.parentElement.parentElement.children;
        // for (let i = sourceHTMLCollection.length - 1; i >= 0; --i) {
        //   sourceHTMLCollection.item(i).remove();
        // }
        document.getElementById("source-" + sourceNumber).remove();
        document.getElementById("tab-" + captureKey).remove();
        delete imgArray[captureKey];
        if (document.querySelectorAll("#main-tabs>*").length > 1) {
          M.Tabs.init(document.querySelector("#main-tabs"));
        }
      }
    });
  }
}

function stop_robot_capture(buttonElement, captureKey, sourceNumber) {
  let captureKeyFixed = captureKey.replace(/\-((top)|(bottom))\-image/, "");
  socket.emit("stop-robot-capture", captureKeyFixed, function (result) {
    if (result === "success") {
      // let sourceHTMLCollection =
      //   buttonElement.parentElement.parentElement.children;
      // for (let i = sourceHTMLCollection.length - 1; i >= 0; --i) {
      //   sourceHTMLCollection.item(i).remove();
      // }
      document.getElementById("source-" + sourceNumber).remove();
      document.getElementById("tab-" + captureKeyFixed + "-top-image").remove();
      document
        .getElementById("tab-" + captureKeyFixed + "-bottom-image")
        .remove();
      delete imgArray[captureKeyFixed + "-top-image"];
      delete imgArray[captureKeyFixed + "-bottom-image"];
      if (document.querySelectorAll("#main-tabs>*").length > 1) {
        M.Tabs.init(document.querySelector("#main-tabs"));
      }
    }
  });
}

function request_split_canvas(canvasPaths, splitCanvasNumber) {
  setTimeout(function () {
    let splitCanvasPath = "split-canvas-" + splitCanvasNumber;
    let thisCanvas = document.getElementById(
      "source-" + String(splitCanvasNumber)
    ).children[0];

    let context = thisCanvas.getContext("2d");
    let canvasCurrentX = 0;
    let canvasCurrentY = 0;
    let currentCanvasIndex = 0;

    for (canvasPath of canvasPaths) {
      if (canvasPaths.length == 2) {
        if (currentCanvasIndex == 0) {
          context.drawImage(
            imgArray[canvasPath],
            canvasCurrentX,
            canvasCurrentY,
            thisCanvas.width / 2,
            thisCanvas.height
          );
          canvasCurrentX = thisCanvas.width / 2;
        }
        if (currentCanvasIndex == 1) {
          context.drawImage(
            imgArray[canvasPath],
            canvasCurrentX,
            canvasCurrentY,
            thisCanvas.width / 2,
            thisCanvas.height
          );
        }
      }
      if (canvasPaths.length > 2 && canvasPaths.length <= 4) {
        if (currentCanvasIndex == 0) {
          context.drawImage(
            imgArray[canvasPath],
            canvasCurrentX,
            canvasCurrentY,
            thisCanvas.width / 2,
            thisCanvas.height / 2
          );
          canvasCurrentX = thisCanvas.width / 2;
        }
        if (currentCanvasIndex == 1) {
          context.drawImage(
            imgArray[canvasPath],
            canvasCurrentX,
            canvasCurrentY,
            thisCanvas.width / 2,
            thisCanvas.height / 2
          );
          canvasCurrentX = 0;
          canvasCurrentY = thisCanvas.height / 2;
        }
        if (currentCanvasIndex == 2) {
          context.drawImage(
            imgArray[canvasPath],
            canvasCurrentX,
            canvasCurrentY,
            thisCanvas.width / 2,
            thisCanvas.height / 2
          );
          canvasCurrentX = thisCanvas.width / 2;
          canvasCurrentY = thisCanvas.height / 2;
        }

        if (currentCanvasIndex == 3) {
          context.drawImage(
            imgArray[canvasPath],
            canvasCurrentX,
            canvasCurrentY,
            thisCanvas.width / 2,
            thisCanvas.height / 2
          );
        }
        currentCanvasIndex++;
      }
    }

    requestAnimationFrame((ts) => {
      request_split_canvas(canvasPaths, splitCanvasNumber);
    });
  }, 1000 / parseInt(document.querySelector("#fps-select").value));
}

//function to start vrep capture from simulation
function start_vrep_capture(path) {
  let currentSourceNumber = document.querySelectorAll("#source-content>*")
    .length;
  let port = 19997 //default port
  if(path.search(/.+:.+/) >= 0){
    // found port in ip string
    let ipPortRegex = /(.+):(.+)/;
    let match = ipPortRegex.exec(path);
    path = match[1];
    port = match[2];
  }
  socket.emit(
    "start-vrep-video",
    path,
    String(currentSourceNumber + 1),
    port,
    function (
      top_image_tab,
      top_image_frame,
      bottom_image_tab,
      bottom_image_frame
    ) {
      $("#main-tabs").append(top_image_tab);
      $("#source-content").append(top_image_frame);
      $("#main-tabs").append(bottom_image_tab);
      $("#source-content").append(bottom_image_frame);
      M.Tabs.init(document.querySelector("#main-tabs"));

      requestAnimationFrame((timestamp) =>
        request_vrep_image(path + "-" + port, currentSourceNumber)
      );
    }
  );
}

//function in called in loop to atualize vrep capture
function request_vrep_image(requestedPath, sourceNumber) {
  setTimeout(function () {
    let functionName = false;
    let selectedIndex = "0";
    try {
      selectedIndex = document.querySelector(
        "li.active input.debug-image-index-selector:checked + span"
      ).innerText;
    } catch (error) {
      //console.log(error)
    }
    try {
      functionName = document.querySelector(
        "#function-selector-div>ul>li.active>div>span"
      ).innerText;
    } catch (error) {
      // console.log(error);
    }

    socket.emit(
      "request-vrep-img",
      requestedPath,
      functionName,
      selectedIndex,
      function (
        top_img_byte_string,
        bottom_img_byte_string,
        returnedPath, //TODO: remove path
        debugImageSize
      ) {
        let topImgPath = requestedPath + "-top-image";
        if (!(topImgPath in imgArray)) {
          // if source is new
          register_new_canvas_image(topImgPath);
        }

        let bottomImgPath = requestedPath + "-bottom-image";
        if (!(bottomImgPath in imgArray)) {
          // if source is new
          register_new_canvas_image(bottomImgPath);
        }
        //populate debug image array index selection
        if (functionName) {
          let indexSelectorDiv = document.querySelector(
            "li.active .debug-image-index-div"
          );
          if (indexSelectorDiv && indexSelectorDiv.childElementCount == 0) {
            //if it is the first time
            debugImageSize = parseInt(debugImageSize);
            for (let i = 0; i < debugImageSize; i++) {
              indexSelectorDiv.appendChild(document.createElement("label"));
              indexSelectorDiv.children[i].appendChild(
                document.createElement("input")
              );
              indexSelectorDiv.children[i].children[0].setAttribute(
                "type",
                "radio"
              );
              indexSelectorDiv.children[i].children[0].setAttribute(
                "name",
                functionName + "-debug-index-selector"
              );
              indexSelectorDiv.children[i].children[0].setAttribute(
                "class",
                "debug-image-index-selector with-gap"
              );
              indexSelectorDiv.children[i].appendChild(
                document.createElement("span")
              );
              indexSelectorDiv.children[i].children[1].innerText = i;
            }
          }
        }

        // write new image
        let oldImgString = imgArray[topImgPath].src.replace(
          "data:image/jpeg;base64,",
          ""
        );
        if (
          top_img_byte_string.localeCompare(oldImgString) ||
          !oldImgString.localeCompare("")
        ) {
          // if strings are different or img.src are empty
          imgArray[topImgPath].src =
            "data:image/jpeg;base64," + top_img_byte_string;
        }

        // write new image
        oldImgString = imgArray[bottomImgPath].src.replace(
          "data:image/jpeg;base64,",
          ""
        );
        if (
          bottom_img_byte_string.localeCompare(oldImgString) ||
          !oldImgString.localeCompare("")
        ) {
          // if strings are different or img.src are empty
          imgArray[bottomImgPath].src =
            "data:image/jpeg;base64," + bottom_img_byte_string;
        }

        requestAnimationFrame((timestamp) =>
          request_vrep_image(requestedPath, sourceNumber)
        );
      }
    );
  }, 1000 / parseInt(document.querySelector("#fps-select").value));
}

// function to stop capture image from vrep simulation
function stop_vrep_capture(buttonElement, captureKey, sourceNumber) {
  let captureKeyFixed = captureKey.replace(/\-((top)|(bottom))\-image/, "");
  socket.emit("stop-robot-capture", captureKeyFixed, function (result) {
    if (result === "success") {
      // let sourceHTMLCollection =
      //   buttonElement.parentElement.parentElement.children;
      // for (let i = sourceHTMLCollection.length - 1; i >= 0; --i) {
      //   sourceHTMLCollection.item(i).remove();
      // }
      document.getElementById("source-" + sourceNumber).remove();
      document.getElementById("tab-" + captureKeyFixed + "-top-image").remove();
      document
        .getElementById("tab-" + captureKeyFixed + "-bottom-image")
        .remove();
      delete imgArray[captureKeyFixed + "-top-image"];
      delete imgArray[captureKeyFixed + "-bottom-image"];
      if (document.querySelectorAll("#main-tabs>*").length > 1) {
        M.Tabs.init(document.querySelector("#main-tabs"));
      }
    }
  });
}

// function to create a new source input, wich is a combination of other inputs
function split_canvas(paths) {
  let currentSourceNumber = document.querySelectorAll("#source-content>*")
    .length;
  socket.emit("split-canvas", String(currentSourceNumber + 1), function (
    cap_tab,
    cap_frame
  ) {
    $("#main-tabs").append(cap_tab);
    $("#source-content").append(cap_frame);
    M.Tabs.init(document.querySelector("#main-tabs"));

    requestAnimationFrame((timestamp) =>
      request_split_canvas(paths, currentSourceNumber + 1)
    );
  });
}

//Function to initialize and open the split canvas chooser modal
function split_modal() {
  $("#modal-split-canvas select>option[value!='']").remove();
  let avaliableSources = [];
  for (tabElement of document.querySelector("#main-tabs").children) {
    if (tabElement.className.includes("tab")) {
      let currentDict = {};
      //create an object in the format of {"Source number" : "source path"}
      currentDict[tabElement.dataset.sourceNumber] = tabElement.id.substr(4);
      avaliableSources.push(currentDict);
    }
  }

  for (source of avaliableSources) {
    let key = Object.keys(source)[0];
    let selectElement = document.querySelector("#modal-split-canvas select");
    selectElement.options[selectElement.options.length] = new Option(
      "Source " + key,
      source[key]
    );
  }
  M.Modal.init(document.getElementById("modal-split-canvas"));
  M.FormSelect.init(document.querySelectorAll("#modal-split-canvas select"));
  M.Modal.getInstance(document.getElementById("modal-split-canvas")).open();
}

//function to change a perception function parameter
function param_change(inputElement, inputType) {
  let paramName = inputElement.labels[0].innerText;
  let paramValue = "";
  let paramFunc = document.querySelector("li.active>.collapsible-header>span")
    .innerText;
  if (inputType === "number") {
    paramValue = inputElement.value;
  } else if (inputType === "bool") {
    // convert js true/false to python True/False
    paramValue =
      inputElement.checked.toString()[0].toUpperCase() +
      inputElement.checked.toString().slice(1);
  }
  socket.emit(
    "param-change",
    paramFunc,
    paramName,
    inputType,
    paramValue,
    function (status) {
      console.log(status);
    }
  );
}

function recording_video_modal() {
  $("#record-video-modal select>option[value!='']").remove();
  let avaliableSources = [];
  for (tabElement of document.querySelector("#main-tabs").children) {
    if (tabElement.className.includes("tab")) {
      let currentDict = {};
      //create an object in the format of {"Source number" : "source path"}
      currentDict[tabElement.dataset.sourceNumber] = tabElement.id.substr(4);
      avaliableSources.push(currentDict);
    }
  }

  for (source of avaliableSources) {
    let key = Object.keys(source)[0];
    let selectElement = document.querySelector("#record-video-modal select");
    selectElement.options[selectElement.options.length] = new Option(
      "Source " + key,
      source[key]
    );
  }
  M.Modal.init(document.getElementById("record-video-modal"));
  M.FormSelect.init(document.querySelectorAll("#record-video-modal select"));
  M.Modal.getInstance(document.getElementById("record-video-modal")).open();
}

//function to start recording video
function start_record_video(selectedSourcePath, recordingName) {
  socket.emit(
    "start-record-video",
    selectedSourcePath,
    recordingName,
    function (isFile, errorMsg) {
      if (!isFile) {
        //toast fail
        console.log(errorMsg);
        return;
      } else {
        //change buttons and disable input
        document.querySelector("#recording-name").disabled = true;
        document.querySelector("#record-buttons").innerHTML = `
        <a class="waves-effect waves-light btn" onclick="stop_record_video()" style="background-color: red;">
        <i class="material-icons left large" style="font-size: 30px">stop</i>
        Finish Recording
        </a>
        `

        console.log("buttons changing");
      }

      requestAnimationFrame((timestamp) =>
        request_record_frame(selectedSourcePath)
      );
    }
  );
}

//function to run in a loop recording video until it is stopped
function request_record_frame(selectedSourcePath) {
  setTimeout(function () {
    socket.emit("request-record-frame", selectedSourcePath, function(recordingStatus){
      if(!recordingStatus){
        return;
      }
      requestAnimationFrame((ts) => {
        request_record_frame(selectedSourcePath);
      });
    });
  }, 1000 / parseInt(document.querySelector("#fps-select").value));
}

function stop_record_video() {
  socket.emit("stop-record-video", function() {
    document.querySelector("#recording-name").disabled = false;
    document.querySelector("#record-buttons").innerHTML = `
    <a class="waves-effect waves-light btn"onclick="recording_video_modal()">
    Record
    </a>
    `

  });
}
