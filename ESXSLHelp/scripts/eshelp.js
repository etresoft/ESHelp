/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

// Change the class on the body to switch to Dark Mode.
function setAppearance(appearanceName)
  {
  var body =
    document.body || document.getElementsByTagName('body')[0];

  body.setAttribute('class', appearanceName);

  return appearanceName;
  }

// Show all search results.
function showall()
  {
  var hiddenItems = document.querySelectorAll(".searchresults li.more");
  
  for(var i = 0; i < hiddenItems.length; ++i)
    hiddenItems[i].removeAttribute('class');

  var showMore = document.querySelectorAll("#showalllink");
  
  for(var i = 0; i < showMore.length; ++i)
    showMore[i].style.display = 'none';

  var hr = document.querySelectorAll("hr.searchresults");
  
  for(var i = 0; i < hr.length; ++i)
    hr[i].style.display = 'none';
  }

function message(text)
  {
  var ul = document.querySelectorAll("ul.searchresults");

  var li = document.createElement("LI");                 // Create a <li> node
  var textnode = document.createTextNode(text);         // Create a text node
  li.appendChild(textnode);                              // Append the text to
  ul[0].appendChild(li);
  }

// Search the web for help.
function searchweb()
  {
  if(window.webkit != undefined)
    window.webkit.messageHandlers.help.postMessage("searchweb");

  else if(window.help != undefined)
    window.help.postMessage("searchweb");
  }