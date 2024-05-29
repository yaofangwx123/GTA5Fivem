	var instance = new Vue({
		  el: '#app',
		  data: {
			message: "",
			companyNew:{},
			formRules:{
				name: [{
						required: true,
						message: getLocal('cmpnamerequire'),
						trigger: 'blur'
					},
					
					{
						min: 5,
						max: 20,
						message: getLocal('txtlen5-20'),
						trigger: 'blur'
					}
				],
				ceoName: [{
						required: true,
						message: getLocal('ceonamerequire'),
						trigger: 'blur'
					},
					
					{
						min: 2,
						max: 20,
						message: getLocal('txtlen2-20'),
						trigger: 'blur'
					}
				]
			}
		  },
		  methods:{
			confirm(form){
				
				
				
				let that = this
				
				this.$refs[form].validate((valid) => {
				        if (valid) {
							
						sendMessageToClient(that,{
							name:that.companyNew.name,
							companyCEOName:that.companyNew.ceoName,
							action:"regiest"
						},function(data){
							
							 notification(that, getLocal('tip'),data.result?'sucess':'error',data.msg)
							 if(data.result){
								 goMainPage()
							 }        
							 		
						},true)
				          
				        } else {
				          console.log('error submit!!');
				          return false;
				        }
				      });
				
				
				
							
				
			},
			cancel(){
				goMainPage()
			}
			
		  },
		  beforeMount() {
		  	this.local = getLocal
		  }
		})