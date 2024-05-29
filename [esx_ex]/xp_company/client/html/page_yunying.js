	var instance = new Vue({
		  el: '#app',
		  data: {
			company:null,
			processBg:'#8e8e8e',
			activeName: 'project',
			fianaces:[],
			financePage:0,
			financeNoMoreData:false,
			activeProjectName:'',
			bigType:[getLocal('payout'),getLocal('payin')],
			subType:[getLocal('typePaySalary'),getLocal('typeProjReward'),getLocal('typeProjFire'),getLocal('typeCmpPay')],
			projectSelectName:"",
			projectChangeSelect:null,

			financeData:[{
				mainType:0,
				money:0
			},
			{
				mainType:1,
				money:0
			}]
		  },
		  computed:
		  {
		
		  },
		  methods:{
			clickProAdmin(project){
			
				this.projectChangeSelect= {staffId : project.staffId,name:project.name,id : project.id,oldStaffId :project.staffId }
			
			},
			changeproadmin(){
				if(this.projectChangeSelect.staffId == this.projectChangeSelect.oldStaffId)
				{
					return
				}
				
				let that = this
				
				messageConfirm(that,getLocal('msgchangeproadmin'),function(result){
					
					if(result)
					{
						sendMessageToClient(that,{
							action: "changeProAmin",
							params: that.projectChangeSelect
						}, function(result_) {
							let result = result_
							that.projectChangeSelect = null	
							notification(that,getLocal('tip'), result.result ? 'success' : 'error', result.result ?getLocal('doSucess'):getLocal('doFail'))
								
							if(result.result)
							{
								that.getCmp()
								
							}
								
							
						
						}, true)
					}
					
					
					})
				
			},
			close(){
				goMainPage()
			},
			getTaskProc(task){
				
				return (task.current*100/task.total).toFixed(2)
			},
			getProjectStaffs(){
				
				let staffs = []
				for(let staff of this.company.staffs)
				{
					if(isStaffHavePermisson(staff,PERMISSION_PROJECT))
					{
						staff.selectEnable = this.projectChangeSelect.staffId != staff.id
						staffs.push(staff)
					}
				}
				
				return staffs
			
			},
			getFinances(pager){
				let that = this
				if(that.financeNoMoreData){
					return
				}
				sendMessageToClient(this,{action:'getCompanyFinances',comId:this.company.id,page:pager},function(result){
					if(result.length == 0){
						that.financeNoMoreData = true
						
					}

					that.fianaces.push(result)
					if(pager != that.financePage){
						that.financePage = pager
					}
					
					
					
				},true)
			},
			getCcTime(time){
				return getCCmTime(time)
			},
			goLastPager(){
				
				if(this.financePage == 0){
					return
				}
				
				--this.financePage
			},
			goNextPager(){
				
				
				
				if((this.financePage + 1)<this.fianaces.length){
					++this.financePage
				}else{
					if(this.financeNoMoreData){
						return
					}
					this.getFinances(this.financePage + 1)
				}
				
				
				
				
			},
			getCompanyFinanceData(){
				let that = this
				sendMessageToClient(this,{action:'getCompanyFinanceData',comId:this.company.id},function(result){
					
					
					
					for(let data of result){
						if(data.mainType == 0){
							that.financeData[0] = data
						}else if(data.mainType == 1){
							that.financeData[1] = data
						}
					}
					
					that.getFinances(0)
				})
			},
			handleClick(tab, event){
				
				if(tab.name == 'finance'){
					this.financePage = 0
					this.financeNoMoreData = false
					this.fianaces = []
					this.getCompanyFinanceData()
				}
				
			},
			handleClickProjects(tab, event){
				
			
				
			},
			getheadUrl(head){
				return 'data:image/png;base64,' + headers[head]
			},
			getCmp(){
				let that = this
				this.local = getLocal
				getMyCompany(this,function(company){
								  that.company = company
								  
								  for(let project of that.company.projects){
									  if(!that.projectSelectName)
									  {
										  that.projectSelectName = project.name
									  }
									  for(let staff of that.company.staffs)
									  {
										  if(staff.id == project.staffId)
										  {
											  project.admin = staff
											   break
										  }
										 
									  }
									  
									
								  }
				})
			}
			},
			
		  mounted() {
			 
			 this.getCmp()
		
			}
		})