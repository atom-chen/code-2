--
-- Author: Your Name
-- Date: 2015-11-20 19:42:32
--

--
-- Author: Your Name
-- Date: 2015-08-26 21:23:35
--
local  Act2ChargCountView = class("OpenChargCountView", base.BaseView)


function Act2ChargCountView:init(  )
	-- body
	self.showtype=view_show_type.UI
	self.view=self:addSelfView()


	self.headerPanel = self.view:getChildByName("Panel_1")
	self.RuleLab = self.headerPanel:getChildByName("Text_5")


	-- self.RuleLab:ignoreContentAdaptWithSize(false)
	-- self.RuleLab:setContentSize(600,60)
	-- self.RuleLab:setPosition(self.RuleLab:getPositionX(),self.RuleLab:getPositionY() - 15)

	self.clonePanel = self.view:getChildByName("Item_Panel")
	self.listView = self.view:getChildByName("ListView_item")
	self.cloneItem = self.view:getChildByName("item")

	self.clonePanel:getChildByName("Button_get"):setEnabled(true)
	self.clonePanel:getChildByName("Button_get"):setBright(false)

	self.view:getChildByName("Panel_footer"):setLocalZOrder(1000)

	
	self.data = {}
	self:inittableView()


	---固定文本抽出

	self.RuleLab:setString(res.str.ACT2_CHARGE_DESC1)
	self.clonePanel:getChildByName("Text_31"):setString(res.str.ACT2_CHARGE_DESC3)
	
	-- proxy.ChargeCount:reqGiftInfo()
	proxy.RichRank:reqOpenChargeCountInfo()
	



end



---创建每个充值奖励
function Act2ChargCountView:createitem(idx)
	-- body
	local gifts = self.data[idx]["gifts"]
	local itemPanel = self.clonePanel:clone()
	local listView = itemPanel:getChildByName("ListView_sub_item")
	listView:setSwallowTouches(false)
	listView:setContentSize(1000,120)
	itemPanel:setSwallowTouches(false)
	for i=1,#gifts do
		local item = self.cloneItem:clone()
		item:setSwallowTouches(false)
		listView:pushBackCustomItem(item)

		local iconFrame = item:getChildByName("btn_goods")
		local iconImg = item:getChildByName("img_goods")
		local textLb = item:getChildByName("text_goods")

		local mid = gifts[i][1]
		local num = gifts[i][2]
		local iconFrameSrc = conf.Act2Charge:getFrameIcon(mid)
		local iconImgSrc = conf.Act2Charge:getIcon(mid)
		local textLbName = conf.Act2Charge:getName(mid)
		local textColor = conf.Act2Charge:getTextColor(mid)

		iconFrame:loadTextureNormal(iconFrameSrc)
		iconImg:loadTexture(iconImgSrc)
		textLb:setString(textLbName .. "x" .. num)
		textLb:setColor(textColor)


		---根据物品名字长度来设置item大小
		--item:setContentSize(textLb:getContentSize().width,item:getContentSize().height)

		iconFrame.mid = mid
		iconFrame:addTouchEventListener(handler(self,self.openItem))

	end

	--领取按钮
	local btnGet = itemPanel:getChildByName("Button_get")
	local label = btnGet:getChildByName("Text_title")
	btnGet:addTouchEventListener(handler(self,self.onBtnGetClicked))
	btnGet.index = self.data[idx]["id"]

	if self.data[idx]["isGet"] == 1 then --可领取
		btnGet:setEnabled(true)
		btnGet:setBright(true)
		label:setString(res.str.HSUI_DESC1)
	elseif self.data[idx]["isGet"] == 2 then
		btnGet:setEnabled(false)
		btnGet:setBright(false)
		btnGet:loadTextureNormal("res/views/ui_res/button/btn_grey_1.png")
		label:setString(res.str.HSUI_DESC1)
	elseif self.data[idx]["isGet"] == 3 then
		btnGet:setEnabled(false)
		btnGet:setBright(false)
		btnGet:loadTextureNormal("res/views/ui_res/button/btn_grey_1.png")
		label:setString(res.str.HSUI_DESC2)
	end

	--领取条件
	local ruleLab = itemPanel:getChildByName("Text_limited")
	
	ruleLab:setString(string.format(res.str.HSUI_DESC3, self.data[idx]["quota"] / 10))
	--ruleLab:setString("累计充值" .. (self.data[idx]["quota"] / 10) .. "元")

	--剩余领取次数
	local leftTimeLab = itemPanel:getChildByName("Text_32")
	local totalTimeLab = itemPanel:getChildByName("Text_33")

	local totalNum = self.data[idx]["count"]
	leftTimeLab:setString(self.data[idx]["leftCount"])
	totalTimeLab:setString("/" .. totalNum)



	return itemPanel
end


--领取按钮 回调
function Act2ChargCountView:onBtnGetClicked( send,eventType )
	if eventType == ccui.TouchEventType.ended then
		--proxy.ChargeCount:reqGetAward(3,send.index)
		proxy.RichRank:reqGetChargeAward(3,send.index)
	end
end


-----打开物品

function Act2ChargCountView:openItem( send,eventType  )
	-- body
	if eventType == ccui.TouchEventType.ended then

		local data = {}
			data.mId = send.mid
		local itype=conf.Item:getType(data.mId)
		if itype ==  pack_type.PRO then
			G_openItem(data.mId)
		elseif itype  == pack_type.EQUIPMENT then 
			G_OpenEquip(data,true)
		else	
			G_OpenCard(data,true)
		end

	end
end


-----活动倒计时
function Act2ChargCountView:timeTick( )
	self.leftTime = self.leftTime - 1
	self.todayTime = self.todayTime - 1
	if self.leftTime <= 0 then
		self:stopAction(self.timeSchedual)
		--如果是主界面进入
		local view = mgr.ViewMgr:get(_viewname.RANKENTY)
		if view then
			view:updateData(res.str.RICH_RANK_DESC37)
		end
		G_mainView()
		return
	end

	if self.todayTime <= 0 then
		self:stopAllActions()
		proxy.RichRank:reqOpenChargeCountInfo()
		return
	end

	--如果是主界面进入
	local view = mgr.ViewMgr:get(_viewname.RANKENTY)
	if view then
		view:updateData(self:getTimeStr(self.leftTime))
	end

end


function Act2ChargCountView:getTimeStr( leftTime )
	--self.leftTime = self.leftTime - 1
	local left = 0
	local day = math.floor(leftTime / (60 * 60 * 24))--天
	left = leftTime - day * 60 * 60 * 24

	local hour = math.floor(left / (60 * 60))--时
	left = left - hour * 60 * 60

	local minute = math.floor(left / 60)--分
	left = left - minute * 60 --秒
	local timeStr

	if day == 0 and hour == 0 and minute == 0 then
		timeStr = string.format(res.str.RICH_RANK_DESC9,left)
	elseif day == 0 and hour == 0 then
		timeStr = string.format(res.str.RICH_RANK_DESC10, minute,left)
	elseif day == 0 then
		timeStr = string.format(res.str.RICH_RANK_DESC11, hour,minute,left)
	else
		timeStr = string.format(res.str.RICH_RANK_DESC12, day,hour,minute,left)
	end

	return timeStr
end


-------网络数据
--请求奖励信息成功返回
function Act2ChargCountView:setGiftInfo( data )
	self.data = conf.Act2Charge:getDataMRLC()
	local avilable = data["awards"]

	for i=1,#self.data do
		local id = self.data[i]["id"]
		local leftCount = avilable[id..""]
		if leftCount then
			self.data[i]["leftCount"] = leftCount
			if leftCount > 0 then-------------------可领取
				self.data[i]["isGet"] = 1 
			elseif leftCount <= 0 then -------------已领取
				self.data[i]["isGet"] = 3 
			end
		else----------------------------------------不能领取
			self.data[i]["isGet"] = 2
			self.data[i]["leftCount"] = self.data[i]["count"]
		end
	end

----排序
	for i=1,table.nums(self.data) - 1 do
		for j=i+1,table.nums(self.data) do
			if self.data[i]["isGet"] > self.data[j]["isGet"] then
				local tmp = self.data[i]
				self.data[i] = self.data[j]
				self.data[j] = tmp

			elseif self.data[i]["isGet"] == self.data[j]["isGet"] then
				if self.data[i]["quota"] > self.data[j]["quota"] then
					local tmp = self.data[i]
					self.data[i] = self.data[j]
					self.data[j] = tmp
				end
			end

		end
	end

	--开始倒计时
	self.leftTime = data["actTime"]
	self.todayTime = data["lastTime"]

	--显示倒计时
	--如果是主界面进入
	local zsStr = string.format(res.str.RICH_RANK_DESC5, data["sumMoney"] / 10 )

	local view = mgr.ViewMgr:get(_viewname.RANKENTY)
	if view then
		view:updateData(self:getTimeStr(self.leftTime),zsStr)
	end


	self.timeSchedual = self:schedule(self.timeTick, 1)
	--累计充值
	
	--self.chargeCount:setString(string.format(res.str.HSUI_DESC7,data["sumMoney"] / 10 ))
	--self.chargeCount:setString("今日已累计充值"..(data["sumMoney"] / 10).."元")
	self.tableView:reloadData()

end


--成功领取奖励
function Act2ChargCountView:getAwardSucc( data )
	--找到领取的奖励位置
	--dump(data)
	for i=1,table.nums(self.data) do
		if self.data[i].id == data.index then
			self.data[i].leftCount = self.data[i].leftCount - 1
			if self.data[i].leftCount <= 0 then--领取完了
				self.data[i]["isGet"] = 3
				local data = self.data[i]
				table.remove(self.data,i)
				table.insert(self.data, data)
				self.tableView:reloadData()
				print("===========w玩")
				return
			else---改变为不可领取
				self.data[i]["isGet"] = 2
				self.tableView:reloadData()
				print("===========未完")
				return
			end
		end
	end

end


--------------------------TableVIew

function Act2ChargCountView:numberOfCellsInTableView(iTable)
	-- body
	--local size=#self.Data[self.packindex]
	--return 0
    return table.nums(self.data)
end

function Act2ChargCountView:scrollViewDidScroll(view)

   -- print("scrollViewDidScroll")
end

function Act2ChargCountView:scrollViewDidZoom(view)
	
   -- print("scrollViewDidZoom")
end

function Act2ChargCountView:tableCellTouched(table,cell)
    print("cell touched at index: " .. cell:getIdx())
end


function Act2ChargCountView:cellSizeForTable(table,idx) 
	local ccsize = self.clonePanel:getContentSize()
    return ccsize.height,ccsize.width
end

function Act2ChargCountView:tableCellAtIndex(table, idx)
	
    local strValue = string.format("%d",idx)
    -- print("index "..strValue .." time" ..os.time())
    local cell = table:dequeueCell()
    --local data= self.Data[self.packindex][idx+1]
    if nil == cell then
        cell = cc.TableViewCell:new()
    else
  		--todo
       local item = cell:getChildByName("item")
       item:removeFromParent()
    end

     local item = self:createitem(idx + 1)
     item:setTouchEnabled(false)
     item:setAnchorPoint(0,0)
     item:setPosition(5,0)
     cell:addChild(item)
     item:setName("item")
    
    --设置每条数据的信息

    return cell
end


function Act2ChargCountView:inittableView(listView,ccsize)
	-- body
	--print("kaishi ="..os.time())
	if not self.tableView then 
		local posx ,posy = self.listView:getPosition()
		local ccsize =  self.listView:getContentSize() 

		self.tableView = cc.TableView:create(cc.size(ccsize.width,ccsize.height))
	    self.tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
	    self.tableView:setPosition(cc.p(posx, posy))
	    self.tableView:setDelegate()
	    self.tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	    self.view:addChild(self.tableView,100)
	
	    self.tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView) ,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --tableView个数
	    self.tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll),cc.SCROLLVIEW_SCRIPT_SCROLL)           --滚动  
	    self.tableView:registerScriptHandler(handler(self, self.scrollViewDidZoom),cc.SCROLLVIEW_SCRIPT_ZOOM)				--放大
	    self.tableView:registerScriptHandler(handler(self, self.tableCellTouched),cc.TABLECELL_TOUCHED)						--点击	
	    self.tableView:registerScriptHandler(handler(self, self.cellSizeForTable),cc.TABLECELL_SIZE_FOR_INDEX)				--xiao	
	    self.tableView:registerScriptHandler(handler(self, self.tableCellAtIndex),cc.TABLECELL_SIZE_AT_INDEX)               --添加
	end 
	--print("end ="..os.time())
	self.tableView:reloadData()
end








return Act2ChargCountView