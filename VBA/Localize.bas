Attribute VB_Name = "Localize"
' NOTE THAT THE CODE IN THIS MODULE IS A PART OF THE LIME CRM BASE SOLUTION AND MAY NOT BE CHANGED.
' ANY CUSTOMIZATIONS OR ADDED FUNCTIONALITY SHOULD BE DONE IN SEPARATE FORMS, MODULES AND CLASS MODULES.
' IF YOU CHOOSE TO IGNORE THIS WARNING AND CHANGE THE CODE IN THIS MODULE, SUPPORT OR VERSION COMPATIBILITY IS
' NO LONGER GUARANTEED.
'
' //The Lime CRM Base Solution group at Lime Technologies

Option Explicit

Private m_LanguageCode As String
Public dicLookup As Scripting.Dictionary
Private Const LOCALIZE_SEPARATOR As String = "$$"
' ##SUMMARY Get dictionary
Public Function getDictionary() As Scripting.Dictionary
    On Error GoTo ErrorHandler
    
    'init if missing
    If dicLookup Is Nothing Then
        Call Localize.SetLanguage(Application.Database.Locale)
    End If
    
    Set getDictionary = dicLookup
    
    Exit Function
    
ErrorHandler:
    Call LC_UI.ShowError("Localize.getDictionary")
End Function
' ##SUMMARY Get the keys for dictionary
Public Function getDictionaryKeys() As Collection
    On Error GoTo ErrorHandler
    Dim oC As New Collection
    Dim oE As Variant
    
    'init if missing
    If dicLookup Is Nothing Then
        Call Localize.SetLanguage(Application.Database.Locale)
    End If
    
    'add variants to collection
    For Each oE In dicLookup.keys
        Call oC.Add(oE)
    Next oE
    
    Set getDictionaryKeys = oC
    
    Exit Function
ErrorHandler:
    Call LC_UI.ShowError("Localize.getDictionaryKeys")
End Function
' ##SUMMARY Set the chosen language
Public Sub SetLanguage(ByVal strLanguageCode As String)
    On Error GoTo ErrorHandler
    
     Select Case strLanguageCode
        Case "sv", "no", "fi", "da":
            m_LanguageCode = strLanguageCode
        Case "en-us", "en_us":
            m_LanguageCode = "en_us"
        Case Else
            m_LanguageCode = "en_us"
            Call Lime.MessageBox(VBA.Replace("The language ""%1"" is not supported!" & VBA.vbCrLf & VBA.vbCrLf & "The actionpad language will be set to English.", "%1", strLanguageCode), VBA.vbOKOnly + VBA.vbInformation)
    End Select
    
    Call LoadDictionary
    
    Exit Sub
ErrorHandler:
    Call LC_UI.ShowError("Localize.SetLanguage")
End Sub
' ##SUMMARY Loads the chosen dictionary
Private Sub LoadDictionary()
    On Error GoTo ErrorHandler:
    Dim oRecord As LDE.Record
    Dim oRecords As New LDE.Records
    Dim sKey As String
                
    Set dicLookup = New Scripting.Dictionary
    dicLookup.CompareMode = VBA.vbTextCompare
    
    ' check if table exists
    If Not Database.Classes.Lookup("localize", lkLookupClassByName) Is Nothing Then
    
        'Get all records
        Call oRecords.Open(Database.Classes("localize"))
        
        For Each oRecord In oRecords
            If VBA.Len(VBA.Trim(oRecord.Value(m_LanguageCode))) > 0 Then
                sKey = GetLookupKey(oRecord.Value("owner"), oRecord.Value("code"))
                If dicLookup.Exists(sKey) = False Then
                    Call dicLookup.Add(GetLookupKey(oRecord.Value("owner"), oRecord.Value("code")), oRecord.Value(m_LanguageCode))
                End If
            End If
        Next oRecord
    
    End If
    
    Exit Sub
ErrorHandler:
    Call LC_UI.ShowError("Localize.LoadDictionary")
End Sub
' ##SUMMARY Check to see that the dictionary is initialized and get the text
Public Function GetText(ByVal strOwner As String, ByVal strCode As String) As String
    On Error GoTo ErrorHandler
    Dim strLookupKey As String
    
    strLookupKey = GetLookupKey(strOwner, strCode)
    
    If dicLookup Is Nothing Then
        Call Localize.SetLanguage(Application.Database.Locale)
    End If
    
    If dicLookup.Exists(strLookupKey) Then
        GetText = dicLookup.Item(strLookupKey)
    Else
        GetText = "ERROR! String not found."
    End If
    
    Exit Function
ErrorHandler:
    Call LC_UI.ShowError("Localize.GetText")
End Function

Private Function GetLookupKey(ByVal strOwner As String, ByVal strCode As String) As String
    On Error GoTo ErrorHandler
    
    GetLookupKey = strOwner + LOCALIZE_SEPARATOR + strCode
    
    Exit Function
ErrorHandler:
    Call LC_UI.ShowError("Localize.GetLookupKey")
End Function

Public Sub LocalizeForm(ByRef oForm As MSForms.UserForm)
    Dim oControl As MSForms.Control
    Dim oCommandButton As MSForms.CommandButton
    Dim oXML As MSXML2.DOMDocument60
    Dim oNode As MSXML2.IXMLDOMNode
    Dim strXML As String
        
    Dim sAttribute As String
    Dim sLocalString As String
    
    'Localize Controls
    For Each oControl In oForm.Controls
        sLocalString = "ERROR! Could not find string"
        Set oXML = New MSXML2.DOMDocument60
        strXML = VBA.Trim(VBA.CStr(oControl.Tag))
        If VBA.Len(strXML) > 0 Then
            Call oXML.loadXML(strXML)
        End If
        
        For Each oNode In oXML.selectNodes("//localize")
            sLocalString = GetLocalizationForXMLNode(oNode, sAttribute)
            
            'Set the attribute
            Select Case TypeName(oControl)
                Case "CommandButton":
                    Select Case VBA.LCase(sAttribute)
                        Case "controltiptext"
                            oControl.Object.ControlTipText = sLocalString
                        Case "accelerator"
                            oControl.Object.Accelerator = sLocalString
                        Case Else
                            oControl.Object.Caption = sLocalString
                    End Select
                Case "Label", "CheckBox":
                    Select Case VBA.LCase(sAttribute)
                        Case "controltiptext"
                            oControl.Object.ControlTipText = sLocalString
                        Case Else
                            oControl.Object.Caption = sLocalString
                    End Select
                Case "TextBox":
                    Select Case VBA.LCase(sAttribute)
                        Case "controltiptext"
                            oControl.Object.ControlTipText = sLocalString
                        Case Else
                            oControl.Object.text = sLocalString
                    End Select
                Case "Frame":
                    Select Case VBA.LCase(sAttribute)
                        Case "controltiptext"
                            oControl.Object.ControlTipText = sLocalString
                        Case Else
                            oControl.Object.Caption = sLocalString
                    End Select
            End Select
        Next oNode
    Next oControl
    
    Exit Sub
ErrorHandler:
    Call LC_UI.ShowError("Localize.LocalizeForm")
End Sub

Private Function GetLocalizationForXMLNode(ByRef oNode As MSXML2.IXMLDOMNode, ByRef sAttribute As String) As String
    Dim sReturn As String
    Dim sOwner As String
    Dim sCode As String
    Dim sClass As String
    Dim sField As String
    
    sReturn = "ERROR! Could not find string"
    
    'Parse settings
    If Not oNode.Attributes.getNamedItem("attribute") Is Nothing Then
        sAttribute = oNode.Attributes.getNamedItem("attribute").text
    Else
        sAttribute = ""
    End If
    If Not oNode.Attributes.getNamedItem("owner") Is Nothing Then
        sOwner = oNode.Attributes.getNamedItem("owner").text
    Else
        sOwner = ""
    End If
    If Not oNode.Attributes.getNamedItem("code") Is Nothing Then
        sCode = oNode.Attributes.getNamedItem("code").text
    Else
        sCode = ""
    End If
    If Not oNode.Attributes.getNamedItem("class") Is Nothing Then
        sClass = oNode.Attributes.getNamedItem("class").text
    Else
        sClass = ""
    End If
    If Not oNode.Attributes.getNamedItem("field") Is Nothing Then
        sField = oNode.Attributes.getNamedItem("field").text
    Else
        sField = ""
    End If
    
    'Get the correct text
    If VBA.Len(sClass) > 0 And VBA.Len(sField) > 0 Then
        sReturn = Database.Classes(sClass).Fields(sField).LocalName
    ElseIf VBA.Len(sClass) > 0 Then
        sReturn = Database.Classes(sClass).LocalName
    ElseIf VBA.Len(sOwner) > 0 And VBA.Len(sCode) > 0 Then
        sReturn = Localize.GetText(sOwner, sCode)
    End If
        
    GetLocalizationForXMLNode = sReturn

End Function


Public Function LocalFieldName(ByVal sClass As String, ByVal sField As String) As String
    Dim sReturn As String
    
    sReturn = ""

    If Database.Classes.Exists(sClass) Then
        If Database.Classes(sClass).Fields.Exists(sField) Then
            sReturn = Database.Classes(sClass).Fields(sField).LocalName
        End If
    End If

    LocalFieldName = sReturn
End Function

Public Function GetLanguage() As String
    GetLanguage = Database.Locale
End Function



