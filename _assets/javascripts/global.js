//= require vendor/detector

//
// Typekit
//
(function(d) {
  if ((new Detector()).detect("Proxima Nova")) {
    return;
  }

  var config = {
    kitId: "twc7vou",
    scriptTimeout: 3000
  },
  h=d.documentElement,t=setTimeout(function(){h.className=h.className.replace(/\bwf-loading\b/g,"")+" wf-inactive";},config.scriptTimeout),tk=d.createElement("script"),f=false,s=d.getElementsByTagName("script")[0],a;h.className+=" wf-loading";tk.src="//use.typekit.net/"+config.kitId+".js";tk.async=true;tk.onload=tk.onreadystatechange=function(){a=this.readyState;if(f||a&&a!="complete"&&a!="loaded")return;f=true;clearTimeout(t);try{Typekit.load(config)}catch(e){}};s.parentNode.insertBefore(tk,s)
})(document);

//
// Google Analytics
//
if (window.location.hostname == "tristandunn.com") {
  (function(i,s,o,g,r,a,m){i["GoogleAnalyticsObject"]=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,"script","//www.google-analytics.com/analytics.js","ga");

  ga("create", "UA-8648594-15", "auto");
  ga("send", "pageview");
}

//
// Cookies
//
var cookie = function(key, value, options) {
  if (value || value === false) {
    options = options || {};

    if (value === false) {
      options.expires = new Date(0);
    } else if (typeof options.expires === "number") {
      var days = options.expires,
          time = options.expires = new Date();

      time.setMilliseconds(time.getMilliseconds() + days * 86400000);
    }

    document.cookie = (key + "=" + value) + "; path=/" +
      (options.expires ? "; expires=" + options.expires.toUTCString() : "");
  } else {
    var result,
        cookies = document.cookie ? document.cookie.split("; ") : [],
        index   = 0,
        length  = cookies.length;

    for (; index < length; index++) {
      var parts  = cookies[index].split("="),
          name   = parts.shift(),
          cookie = parts.join("=");

      if (key === name) {
        result = cookie;
      }
    }

    return result;
  }
};

//
// Newsletter Prompts
//
(function() {
  if (cookie("subscribed")) {
    return;
  }

  var form = document.querySelector(".newsletter form");

  if (form) {
    form.addEventListener("submit", function(event) {
      cookie("subscribed", true, { expires: 365 });
    }, false);
  }
})();
