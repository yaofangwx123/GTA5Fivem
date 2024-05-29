var instance = new Vue({
		  el: '#app',
		  data: {
			company:null
		  },
		  methods:{
		
		  },
		  mounted() {
			  
		  	let params = new URLSearchParams(location.search);
		  	//let [comId, comName] = [params.get('comId'), params.get('comName')];
			  sendMessageToClient(this,{
					action:"getMyCompany"
				},function(result){
					//console.log("getMyCompany " +result);
					that.company = JSON.parse(result)
				
				})
			
		  }

		})

		
	