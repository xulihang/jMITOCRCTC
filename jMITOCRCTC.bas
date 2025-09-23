B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
Sub Class_Globals
	Private engine As JavaObject
	Private th As Thread
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	th.Initialise("th")
End Sub

Public Sub loadModelAsync(modelPath As String,vocabPath As String) As ResumableSub
	Dim map1 As Map
	map1.Initialize
	map1.Put("modelPath",modelPath)
	map1.Put("vocabPath",vocabPath)
	th.Start(Me,"loadModelUsingMap",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	engine = map1.Get("engine")
	Return engine
End Sub

Public Sub loadModel(modelPath As String,vocabPath As String)
	engine.InitializeNewInstance("com.xulihang.OCRCTC",Array(modelPath,vocabPath))
End Sub

Sub DoProcessingAsync(map1 As Map) As ResumableSub
	Dim b() As Boolean = Array As Boolean(False)
	TimeOutImpl(10000, b)
	th.Start(Me,"recognizeUsingMap",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	If b(0) = False Then
		b(0) = True
		CallSubDelayed2(Me, "Recognized", True)
	End If
	Return endedOK
End Sub

Sub TimeOutImpl(Duration As Int, b() As Boolean)
	Sleep(Duration)
	If b(0) = False Then
		b(0) = True
		Log("time out")
		CallSubDelayed2(Me, "Recognized", False)
	End If
End Sub

Public Sub recognizeAsync(image As cvMat) As ResumableSub
	Dim result As Map
	Dim map1 As Map
	map1.Initialize
	map1.Put("image",image)
	DoProcessingAsync(map1)
	wait for Recognized(Success As Boolean)
	If Success=True Then
		result = map1.Get("result")
	End If
	Return result
End Sub

Public Sub WrapResults(jo As JavaObject) As Map
	Dim result As Map
	result.Initialize
	result.Put("text",jo.GetField("text"))
	Dim chars As List = jo.GetField("chars")
	Dim wrappedChars As List
	wrappedChars.Initialize
	For Each charJO As JavaObject In chars
		Dim wrappedChar As Map
		wrappedChar.Initialize
		wrappedChar.Put("character",charJO.GetField("character"))
		wrappedChar.Put("fr",charJO.GetField("fr"))
		wrappedChar.Put("fg",charJO.GetField("fg"))
		wrappedChar.Put("fb",charJO.GetField("fb"))
		wrappedChar.Put("br",charJO.GetField("br"))
		wrappedChar.Put("bg",charJO.GetField("bg"))
		wrappedChar.Put("bb",charJO.GetField("bb"))
		wrappedChars.Add(wrappedChar)
	Next
	result.Put("chars",wrappedChars)
	Return result
End Sub

Public Sub recognize(image As cvMat) As Map
	Return engine.RunMethod("infer",Array(image.JO))
End Sub

Private Sub recognizeUsingMap(map1 As Map)
	Dim image As cvMat = map1.Get("image")
	Dim result As Map = WrapResults(engine.RunMethod("infer",Array(image.JO)))
	map1.Put("result",result)
End Sub

Private Sub loadModelUsingMap(map1 As Map)
	Dim modelPath As String = map1.Get("modelPath")
	Dim vocabPath As String = map1.Get("vocabPath")
	Dim jo As JavaObject
	jo.InitializeNewInstance("com.xulihang.OCRCTC",Array(modelPath,vocabPath))
	map1.Put("engine",jo)
End Sub
