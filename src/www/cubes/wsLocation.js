
function wsLocation(host_addr, location_callback){
	this.host_addr = host_addr;
	this.location_callback = location_callback;
	this.historic_data = [];
	var self = this;

	this.connect = connect;
	function connect(){
		self.ws = new WebSocket("ws://" + self.host_addr + "/location_ws","location_ws");
		self.ws.binaryType = "arraybuffer";
		self.ws.onmessage = self.onMessage;
		self.ws.onclose = self.onClose;
		self.ws.onopen = self.onOpen;
	}

	this.onMessage = onMessage;
	function onMessage(evt){
		var incoming_data = new Float32Array(evt.data);
		self.historic_data = self.historic_data.concat(incoming_data);

		//Push as many estimates out as is contained within the historic_data array
		while(self.historic_data.length >= 3){
			var cur_estimate = self.historic_data.slice(0, 3);
			self.location_callback(cur_estimate);
			self.historic_data.splice(0, 3);
		}
	}

	this.onClose = onClose;
	function onClose(){

	}

	this.onOpen = onOpen;
	function onOpen(){

	}

}
