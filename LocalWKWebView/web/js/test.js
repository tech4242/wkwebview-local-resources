function test() {
    if(document.getElementById("webkit-h1").style.color == "lightblue") {
        document.getElementById("webkit-h1").style.color = "red";
    } else {
        document.getElementById("webkit-h1").style.color = "lightblue";
    }
}

// fetch() only works when the page has an origin, i.e. when it's served
// through the app:// scheme handler and not loaded from file://
document.addEventListener("DOMContentLoaded", function() {
    var result = document.getElementById("fetch-result");
    result.textContent = "Loaded from " + location.protocol + "//";

    fetch("data.json")
        .then(function(response) { return response.json(); })
        .then(function(data) {
            result.textContent += " · ✅ " + data.message;
        })
        .catch(function(error) {
            result.textContent += " · ❌ fetch() failed: " + error.message;
        });
});
