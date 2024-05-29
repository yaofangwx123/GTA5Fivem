	


	var instance = new Vue({
		  el: '#app',
		  data: {
			isShowMenu:false,
			company:null,
			debug:false,
			dialogAttr:false,
			dialogType:0,
			staffHire:null,
			departments:[],
			permissons:[],
			processBg:'#8e8e8e',
			project:null,
			finance:null,
			staffFire:null,
			staffReqSalary:[],
			staffReqTmpWork:[],
			agreeTimedown:0,
			agreeTimedownInteval:null,
			baseData:{}
			
		  },
		  methods:{
			 
			  getheadUrl(head){
			  	return 'data:image/png;base64,' + headers[head]
			  },
			goPager(page){
				let url = page +(this.isShowRegCompany()?"":("?comId="+this.company.id+"&comName="+this.company.name))
				window.location.href = url
			},
			getIconURL(){
				let url = 'https://nui-img/'+this.staffHire.head+'/'+this.staffHire.head
				return url
			},
			isShowDialog(type){
				return type == this.dialogType
			},
			isShowRegCompany(){
				return !this.company || !this.company.id 
			},
			hireStaff(result){
				let that = this
				sendMessageToClient(instance,{action:'hireStaffResult',result:result,staff:this.staffHire},function(result){
					
					notification(instance,getLocal('tip'),result.result?'success':'error')
					that.dialogType = 0
					that.exit()
				},true)
			},
			staffAutoFire(result){
				let that = this
				if(this.agreeTimedownInteval){
					clearInterval(this.agreeTimedownInteval)
				}
				sendMessageToClient(instance,{action:'autoFireJuge',result:result,staff:this.staffFire,baseData:this.baseData},function(result){
					
					notification(instance,getLocal('tip'),result.result?'success':'error')
					that.dialogType = 0
					that.staffFire = null
					that.exit()
				},true)
			},
			staffTmpworkResult(result){
				let that = this
				if(this.agreeTimedownInteval){
					clearInterval(this.agreeTimedownInteval)
				}
				sendMessageToClient(instance,{action:'tmpoffworkJuge',result:result,staff:this.staffReqTmpWork[0].staff,baseData:this.staffReqTmpWork[0].baseData},function(result){
					
					notification(instance,getLocal('tip'),result.result?'success':'error')
					if(that.staffReqTmpWork.length == 1){
						that.staffReqTmpWork = []	
						that.dialogType = 0
						that.exit()
					}else{
						that.staffReqTmpWork.shift()
					}
					
				},true)
			},
			getStringTime(time){
					return getCCmTime(time)
			},
			pullSalaryStaff(result){
				
				let that = this
				
				sendMessageToClient(instance,{action:'pullSalaryStaff',result:result,staff:this.staffReqSalary[0]},function(result){
					
					notification(instance,getLocal('tip'),result.result?'success':'error')
					if(that.staffReqSalary.length == 1){
						that.staffReqSalary = []	
						that.dialogType = 0
						that.exit()
					}else{
						that.staffReqSalary.shift()
					}
					
				},true)
				
			},
			projectResult(result){
				let that = this
				sendMessageToClient(instance,{action:'projectResult',result:result,project:this.project},function(result){
					
					notification(instance,getLocal('tip'),result.result?'success':'error')
					that.dialogType = 0
					that.exit()
				},true)
			},
	
		    financeResult(result){
					let that = this
					sendMessageToClient(instance,{action:'financeResult',result:result,finance:this.finance},function(result){
						
						notification(instance,getLocal('tip'),result.result?'success':'error')
						that.dialogType = 0
						that.exit()
					},true)
			},
			exit(){
				this.isShowMenu = false
				sendMessageToClient(this,{action : 'close'},function(){})
			}
		  },
		  beforeMount() {
		  	
		  },
		  mounted() {
			 
			 this.local = getLocal
			  
		  	let params = new URLSearchParams(location.search);
		  	//let [comId, comName] = [params.get('comId'), params.get('comName')];
		  	let visible = params.get('visible')
			let that = this
			if(visible){
				getMyCompany(this,function(result){
						//console.log("getMyCompany " +result);
						that.company = result
					})
				that.isShowMenu = true
				
			}
			
			if(this.debug)
			{
				this.isShowMenu = true
				this.dialogType = 1
				this.staffHire = {}
			}
		  }

		})

		
		window.addEventListener('message', (event) => {
			
			
			
			if (event.data.action === 'open') {
				
			instance.company = event.data.company
			
			if(event.data.reqData){
				
				if(event.data.permissonId){
					
					if(event.data.permissonId == 2){
							//event.data.staffHire.name = event.data.staffHire.sex == 1?getMaleName():getFemaleName()
							instance.staffHire = event.data.reqData
							instance.staffHire.departmentName = getDepartmentById(instance.staffHire.departmentId,instance.company.departments).name
							instance.staffHire.seatName = getChairById(instance.staffHire.seatId,instance.company.chairs).txt
							
							instance.isShowMenu = true
							instance.dialogType = 2
							
						}
					else if(event.data.permissonId == 4){
						
						if(event.data.reqData.subType == 2){
							
							instance.finance = event.data.reqData
							instance.dialogType = 42
						}else{
							instance.project = event.data.reqData
							
							
							instance.project.endTime_ = getCCmTime(instance.project.endTime)
							instance.project.createTime_ = getCCmTime(instance.project.createTime)
							instance.dialogType = 4
						}
						
						
						
						//instance.project.tasks_ = JSON.parse(instance.project.tasks)
						//console.log(JSON.stringify(instance.project.tasks_ ))
						instance.isShowMenu = true
						
					}
					else if(event.data.permissonId == 1){
						instance.finance = event.data.reqData
						instance.isShowMenu = true
						instance.dialogType = 1
						//console.log("show finance--------> "+instance.finance.money)
					}else if(event.data.permissonId == 3){
						
						instance.baseData = event.data.baseData
						//console.log("kkk-get auto fire request "+JSON.stringify(instance.company.staffs)+" staffId "+event.data.reqData.id)
						if(instance.company){
							for(let staff of instance.company.staffs){
								//console.log('staff.id '+staff.id+" type "+(typeof(staff.id))+" event.data.reqData.id "+event.data.reqData.id +" type "+(typeof(event.data.reqData.id)))
								if(staff.id == event.data.reqData.id)
								{
									if(instance.agreeTimedownInteval){
										clearInterval(instance.agreeTimedownInteval)
									}
									instance.staffFire = staff
									//console.log("kkk-get staffFire "+JSON.stringify(instance.staffFire))
									instance.agreeTimedown = Time_AutoAgree
									instance.agreeTimedownInteval = setInterval(function(){
										--instance.agreeTimedown
										if(instance.agreeTimedown == 0){
											clearInterval(instance.agreeTimedownInteval)
											instance.staffAutoFire(false)
										}
									},1000)
									
									break
								}
							}
						}
						if(instance.staffFire){
							instance.isShowMenu = true
							instance.dialogType = 3
						}else{
							console.log("not found the staff hire")	
							instance.dialogType = 0
							instance.exit()
						}
						
						//console.log("show finance--------> "+instance.finance.money)
					}		
				}
				
				else {
					if(event.data.doType == 0){
						instance.isShowMenu = true
						instance.dialogType = 5
						instance.staffReqSalary.push(event.data.reqData)
					}else if(event.data.doType == 1){
						instance.isShowMenu = true
						instance.dialogType = 6
						instance.staffReqTmpWork.push({staff : event.data.reqData,baseData : event.data.baseData})
					}
						
				}	
							
				
				
			}else{
				instance.isShowMenu = true
				console.log("just open "+instance.dialogType)
			}
			
				
			}else 	if (event.data.action === 'close') {
				
			instance.isShowMenu = false	
				
			 /*  $.post('http://xp_company/htmlEvent', JSON.stringify({
				 username: "Five",
				 password: "reborn"})) */
				 
			}
			else 	if (event.data.action === 'close dialog') {
			if(instance.dialogType != 0)
			{
				instance.isShowMenu = false
				instance.dialogType = 0
				sendMessageToClient(instance,{action:'clearFocused'})
			}
			
				
			 /*  $.post('http://xp_company/htmlEvent', JSON.stringify({
				 username: "Five",
				 password: "reborn"})) */
				 
			}
		});