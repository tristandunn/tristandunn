(function() {
  if (!document.cookie.match("subscribed=true")) {
    return;
  }

  document.querySelector("body").classList.add("subscribed");
})();
