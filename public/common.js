function changeContent(eltId, value) {
	document.getElementById(eltId).innerHTML=value;
}

function markread(linkId) {
	var domId = 'readstatus_' + linkId;
	var oldValue = document.getElementById(domId).innerHTML;
	var repVal = "";
	var qValue = -1;
	if (oldValue=="Read") {
		repVal = "Unread";
		qValue = 0;
	} else {
		repVal = "Read";
		qValue = 1;
	}
	var retFunction = function () { changeContent('readstatus_' + linkId, repVal); }; 
	xmlRequest('POST', '/s/read/' + linkId + '/' + qValue, retFunction);
}

function xmlRequest(requestType, url, successFunction) {
	var req = new XMLHttpRequest();
	req.open(requestType, url, true);
	req.onreadystatechange = function (aEvt) {
		if(req.readyState == 2) {
			if(req.status == 201 || req.status == 200) {
				successFunction();
			} else {
				failureFunction();
			}
		}
	}
	req.send(null);
}
