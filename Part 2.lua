local W=game:GetService("Workspace")
local AS=game:GetService("AssetService")
local IS=game:GetService("InsertService")
local S=getgenv().FEC
local A,V,N=CFrame.Angles,Vector3.new,CFrame.new

S.animIds={
 Climb="rbxassetid://507765644",
 SpiderRun="rbxassetid://1083182000",
 SpiderIdle="rbxassetid://1083445855",
 ClimbOver="rbxassetid://656117878",
 Ceil="rbxassetid://1083222527"
}

function S.stopTracks()
 for _,tr in pairs(S.tracks)do if tr and tr.IsPlaying then tr:Stop(0.12)end end
 S.tracks={}
end

function S.unpackUGC()
 pcall(function()
  local info=AS:GetBundleDetailsAsync(245332605334281)
  for _,it in ipairs(info.Items or{})do
   if it.Type=="Asset"then
    local ok,mdl=pcall(function()return IS:LoadAsset(it.Id)end)
    if ok and mdl then
     for _,d in ipairs(mdl:GetDescendants())do
      if d:IsA("Animation")and d.AnimationId~=""then
       local pn=string.lower(d.Parent.Name)
       if string.find(pn,"run")or string.find(pn,"walk")then S.animIds.SpiderRun=d.AnimationId
       elseif string.find(pn,"idle")then S.animIds.SpiderIdle=d.AnimationId
       elseif string.find(pn,"climb")then S.animIds.Climb=d.AnimationId end
      end
     end
    end
   end
  end
 end)
 pcall(function()
  local ok,mdl=pcall(function()return IS:LoadAsset(117220698427723)end)
  if ok and mdl then
   for _,d in ipairs(mdl:GetDescendants())do
    if d:IsA("Animation")and d.AnimationId~=""then S.animIds.ClimbOver=d.AnimationId break end
   end
  end
 end)
end

function S.loadTracks(hum)
 S.stopTracks()
 local anim=hum:FindFirstChildOfClass("Animator")if not anim then return end
 task.spawn(function()
  S.unpackUGC()
  for key,aid in pairs(S.animIds)do
   local a=Instance.new("Animation")a.AnimationId=aid
   local ok,tr=pcall(function()return anim:LoadAnimation(a)end)
   if ok and tr then tr.Priority=Enum.AnimationPriority.Action tr.Looped=true S.tracks[key]=tr end
  end
 end)
end

function S.solveArmIK(uT,sh,el,tgt,uL,lL,pol)
 if not uT or not sh or not el then return end
 local bCF=uT.CFrame*sh.C0
 local lT,lP=bCF:PointToObjectSpace(tgt),bCF:VectorToObjectSpace(pol)
 local d=lT.Magnitude if d<0.05 then return end
 local cD=math.clamp(d,math.abs(uL-lL)+0.12,(uL+lL)*0.96)
 local cosS=math.clamp((uL^2+cD^2-lL^2)/(2*uL*cD),-1,1)
 local cosE=math.clamp((uL^2+lL^2-cD^2)/(2*uL*lL),-1,1)
 local dir=lT.Unit local rt=dir:Cross(lP)
 rt=rt.Magnitude<0.001 and V(1,0,0)or rt.Unit
 sh.Transform=CFrame.fromMatrix(V(),rt,-dir,-rt:Cross(dir).Unit)*A(math.acos(cosS),0,0)
 el.Transform=A(math.pi-math.acos(cosE),0,0)
end

-- Syncs 100% FE Joystick Arm Speed/Height + Dead-Weight Legs (Spider Mode kept untouched!)
function S.syncReanim(realJ,hrCF,t,sway,tilt,onCeil,pR,pU,isVault,mvg,hL,hR,armSpd)
 local trk=S.tracks
 for _,tr in pairs(trk)do if not tr.IsPlaying then tr:Play(0.1)end end
 local isTurn,isSp=(S.turnT>0),(S.mode=="Spider")
 local function set(tr,wt,spd)
  if tr then tr:AdjustWeight(wt,0.08)if spd~=nil then tr:AdjustSpeed(spd)end end
 end

 if isVault or isTurn then
  set(trk.ClimbOver,1.0,isVault and 1.65 or 1.35)
  set(trk.Climb,0.01,0)set(trk.SpiderRun,0.01,0)
  set(trk.SpiderIdle,0.01,0)set(trk.Ceil,0.01,0)
 elseif isSp then
  set(trk.ClimbOver,0.01,0)set(trk.Climb,0.01,0)set(trk.Ceil,0.01,0)
  set(trk.SpiderRun,mvg and 1.0 or 0.05,mvg and 2.4 or 0)
  set(trk.SpiderIdle,mvg and 0.05 or 1.0,1.0)
 else
  -- FE Joystick / Direct Arm Scrubbing: everyone sees your arms move slow or fast!
  local lrDiff=(S.posL-S.posR):Dot(pU)
  local asym=math.clamp(math.abs(lrDiff)*0.35,0,0.45)
  set(trk.ClimbOver,asym,0)
  if trk.ClimbOver and trk.ClimbOver.Length>0 then
   trk.ClimbOver.TimePosition=0.28*trk.ClimbOver.Length
  end
  set(trk.SpiderRun,0.01,0)
  if trk.Climb then
   trk.Climb:AdjustWeight(onCeil and 0.35 or(mvg and 1.0 or 0.45),0.08)
   trk.Climb:AdjustSpeed(0)
   if trk.Climb.Length>0 then
    -- Maps L/R hand height offset & phase directly to FE climb keyframes!
    local keyPos=(S.phase+(lrDiff*0.18))%1
    trk.Climb.TimePosition=keyPos*trk.Climb.Length
   end
  end
  set(trk.SpiderIdle,(not mvg and not onCeil and asym<0.1)and 0.55 or 0.01,0.8)
  set(trk.Ceil,onCeil and 0.85 or 0.01,0.5)
 end

 if not S.rig then return end
 local rHr=S.rig:FindFirstChild("HumanoidRootPart")if rHr then rHr.CFrame=hrCF end
 local r=S.rigJ for _,m in pairs(r)do m.Transform=N()end

 if isSp then
  for nm in pairs(r)do if realJ[nm]then realJ[nm].Transform=N()end end
  return
 end

 local lGrav=hrCF:VectorToObjectSpace(V(0,-1,0))
 local hPitch=math.clamp(math.atan2(-lGrav.Z,-lGrav.Y)*0.55,-0.55,0.65)
 local hRoll=math.clamp((-sway*1.65)+math.sin(t*1.1)*0.04,-0.55,0.55)
 local oneYaw=(hL and not hR and -0.35)or(hR and not hL and 0.35)or 0

 if r.Root then r.Root.Transform=A(hPitch*0.35,oneYaw,hRoll*0.45)end
 if r.Waist then r.Waist.Transform=A(hPitch*0.65,-oneYaw*0.4,hRoll*0.75)end
 if r.Neck then r.Neck.Transform=A(onCeil and 0.85 or 0.65,-tilt*0.7-oneYaw*0.5,-hRoll*0.4)end
 if r.LeftHip then r.LeftHip.Transform=A(hPitch*0.85+math.sin(t*1.3)*0.04,0,-0.08+hRoll*0.95)end
 if r.LeftKnee then r.LeftKnee.Transform=A(-0.22-math.abs(hRoll)*0.35,0,0)end
 if r.LeftAnkle then r.LeftAnkle.Transform=A(-0.35,0,0)end
 if r.RightHip then r.RightHip.Transform=A(hPitch*0.95-math.sin(t*1.3)*0.04,0,0.08+hRoll*0.95)end
 if r.RightKnee then r.RightKnee.Transform=A(-0.28-math.abs(hRoll)*0.35,0,0)end
 if r.RightAnkle then r.RightAnkle.Transform=A(-0.38,0,0)end

 local uT=S.rig:FindFirstChild("UpperTorso")
 local lA=S.rig:FindFirstChild("LeftUpperArm")
 local lF=S.rig:FindFirstChild("LeftLowerArm")
 local rA=S.rig:FindFirstChild("RightUpperArm")
 local rF=S.rig:FindFirstChild("RightLowerArm")
 local pL=onCeil and(-pU*0.9-pR*0.2)or(-pU*0.95+S.wNorm*0.3-pR*0.2)
 local pR2=onCeil and(-pU*0.9+pR*0.2)or(-pU*0.95+S.wNorm*0.3+pR*0.2)
 if hL then S.solveArmIK(uT,r.LeftShoulder,r.LeftElbow,S.posL,lA and lA.Size.Y or 1.15,lF and lF.Size.Y or 1.15,pL)end
 if hR then S.solveArmIK(uT,r.RightShoulder,r.RightElbow,S.posR,rA and rA.Size.Y or 1.15,rF and rF.Size.Y or 1.15,pR2)end
 for nm,rM in pairs(r)do if realJ[nm]then realJ[nm].Transform=rM.Transform end end
end

function S.traceSurface(oldP,candP,mv,nrm,wR,rp)
 if mv.Magnitude<0.001 then return nil,nil,false end
 local mD=mv.Unit
 local inW=W:Raycast(oldP+nrm*0.45,mD*(mv.Magnitude+1.35),rp)
 if inW and inW.Normal:Dot(nrm)<0.72 then return inW.Position+inW.Normal*0.35,inW.Normal,true end
 if mD.Y>0.25 then
  local cH=W:Raycast(candP-V(0,0.4,0)+nrm*0.4,V(0,2.6,0),rp)
  if cH and cH.Normal.Y<-0.5 then return cH.Position+cH.Normal*0.35,cH.Normal,true end
 end
 local dH=W:Raycast(candP+nrm*1.6,-nrm*3.8,rp)
 if dH then return dH.Position+dH.Normal*0.35,dH.Normal,dH.Normal:Dot(nrm)<0.72 end
 local sD=mD:Dot(wR)
 if math.abs(sD)>0.08 and nrm.Y>-0.5 then
  local sG=sD>0 and 1 or -1
  for _,depth in ipairs({0.8,1.5,2.2})do
   local cR=W:Raycast(candP-nrm*depth+wR*(sG*1.85),-wR*(sG*3.6),rp)
   if cR then return cR.Position+cR.Normal*0.35,cR.Normal,true end
  end
 end
 if nrm.Y>-0.5 then
  local tH=W:Raycast(candP+V(0,1.4,0)-nrm*0.45,V(0,-2.6,0),rp)
  if tH then return tH.Position+V(0,0.28,0)+nrm*0.28,nrm,false end
 end
 return nil,nil,false
end
print("Part 2 Loaded!")
