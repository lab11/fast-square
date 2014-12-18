
function wsLocation(host_addr, scene_context, color){
	this.host_addr = host_addr;
	this.historic_data = [];
	this.scene_context = scene_context;
	this.offset = Math.random();

	//Add in particles which will show the last N position estimates animated in time
	this.estimateHistory = 60;
	this.estimateCur = 0;
	this.estimateValid = 0;
	this.estimates = new THREE.Group();
	var estimateMaterial = new THREE.SpriteMaterial({ color: color, map: THREE.ImageUtils.loadTexture("particle.png"), blending: THREE.AdditiveBlending, transparent: true });

	for(var p = 0; p < this.estimateHistory; p++){
		var px = Math.random() * 5 - 2.5;
		var py = Math.random() * 5 - 2.5;
		var pz = Math.random() * 5 - 2.5;
		var estimate = new THREE.Sprite(estimateMaterial.clone());
		estimate.position.set(px, py, pz);
		estimate.scale.set(0, 0, 1.0);

		this.estimates.add(estimate);
	}

	//Create the particle system
	scene_context.add(this.estimates);

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
		for(var ii=0; ii < incoming_data.length; ii++){
			self.historic_data.push(incoming_data[ii]);
		}

		//Push as many estimates out as is contained within the historic_data array
		while(self.historic_data.length >= 3){
			var cur_estimate = self.historic_data.slice(0, 3);
			self.updateLocation(cur_estimate);
			self.historic_data.splice(0, 3);
		}
	}
   
	this.updateLocation = updateLocation;
	function updateLocation(estimate) {
		//(everything is in decimeters...)
		var nx = estimate[1] - room_y/2;
		var ny = estimate[2] - room_z/2 + self.offset;
		var nz = -(estimate[0] - room_x/2);

		//Increment new estimate index
		self.estimateCur++;
		self.estimateCur = self.estimateCur % self.estimateHistory;
		if(self.estimateValid < self.estimateHistory) self.estimateValid++;

		//Update the sprite's position to reflect the new estimate
		var sprite = self.estimates.children[self.estimateCur];
		sprite.position.set(nx, ny, nz);

		//Implement fade in size for previous estimates
		for(var ii=0; ii < self.estimateHistory; ii++){
			var ei = (self.estimateCur + 1 + ii) % self.estimateHistory;
			var sprite = self.estimates.children[ei];
			var scale = ii/self.estimateHistory;
			if(self.estimateHistory-ii <= self.estimateValid)
				sprite.scale.set(scale/5, scale/5, 1.0);
		}
	}

	this.onClose = onClose;
	function onClose(){

	}

	this.onOpen = onOpen;
	function onOpen(){
	}

}
