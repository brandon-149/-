Attribute VB_Name = "modHtmlTOC"
' ========================================
' htmlTOC - 웹 페이지에서 특정 div의 텍스트 추출
' ========================================
'
' 사용법: =htmlTOC(B2, "div_TOC_All")
'   B2: 웹 페이지 URL
'   "div_TOC_All": 추출할 div의 ID
'
' 동작 방식:
'   1단계: URL의 HTML을 가져와서 해당 div를 직접 찾음
'   2단계: 못 찾으면 AJAX 컨텐츠(알라딘 등)에서 자동으로 찾음
'
' 최적화:
'   - URL별 HTML 캐시 (같은 URL 중복 요청 방지)
'   - URL+divId별 결과 캐시 (같은 조합 중복 파싱 방지)
'
' 캐시 초기화: ClearHtmlCache 매크로 실행
'
' 참고 라이브러리 (도구 > 참조에서 추가 불필요 - 모두 Late Binding 사용):
'   - MSXML2.ServerXMLHTTP.6.0 (HTTP 요청)
'   - ADODB.Stream (인코딩 처리)
'   - htmlfile (HTML 파싱)
'   - Scripting.Dictionary (캐시)
'   - VBScript.RegExp (ISBN 추출)
' ========================================

Option Explicit

' URL별 HTML 응답 캐시
Private htmlCache As Object

' URL+divId별 추출 결과 캐시
Private resultCache As Object

' -------------------------------------------------------
' 메인 함수: URL에서 특정 div의 텍스트를 추출
' -------------------------------------------------------
' url: 웹 페이지 URL (셀 참조 가능)
' divId: 추출할 div 요소의 ID (예: "div_TOC_All")
' -------------------------------------------------------
Public Function htmlTOC(url As Variant, divId As String) As String
    On Error GoTo ErrHandler

    ' 빈 입력 처리
    If Trim(CStr(url)) = "" Or divId = "" Then
        htmlTOC = ""
        Exit Function
    End If

    ' 캐시 초기화
    InitCache

    ' URL 정리 (&amp; -> & 변환)
    Dim cleanUrl As String
    cleanUrl = CleanUrl(CStr(url))

    ' 결과 캐시 확인 - 이미 추출한 적 있으면 바로 반환
    Dim cacheKey As String
    cacheKey = cleanUrl & "|" & divId
    If resultCache.Exists(cacheKey) Then
        htmlTOC = resultCache(cacheKey)
        Exit Function
    End If

    ' 1단계: 메인 URL의 HTML 가져오기
    Dim mainHtml As String
    mainHtml = FetchUrl(cleanUrl)
    If Left(mainHtml, 6) = "Error:" Then
        htmlTOC = mainHtml
        Exit Function
    End If

    ' 2단계: HTML에서 div 직접 찾기
    Dim result As String
    result = ExtractDivText(mainHtml, divId)

    ' 3단계: 못 찾았으면 AJAX 컨텐츠에서 찾기
    ' (알라딘 등 동적 로딩 페이지 대응)
    If result = "" Then
        Dim ajaxHtml As String
        ajaxHtml = FetchAjaxContent(mainHtml, cleanUrl)
        If ajaxHtml <> "" Then
            result = ExtractDivText(ajaxHtml, divId)
        End If
    End If

    ' 결과 캐싱
    If Not resultCache.Exists(cacheKey) Then
        resultCache.Add cacheKey, result
    End If

    htmlTOC = result
    Exit Function

ErrHandler:
    htmlTOC = "Error: " & Err.Description
End Function

' -------------------------------------------------------
' 캐시 딕셔너리 초기화
' -------------------------------------------------------
Private Sub InitCache()
    If htmlCache Is Nothing Then
        Set htmlCache = CreateObject("Scripting.Dictionary")
    End If
    If resultCache Is Nothing Then
        Set resultCache = CreateObject("Scripting.Dictionary")
    End If
End Sub

' -------------------------------------------------------
' URL 정리: HTML 엔티티 디코딩
' 엑셀에서 URL을 붙여넣을 때 &amp;가 포함될 수 있으므로 & 로 변환
' -------------------------------------------------------
Private Function CleanUrl(url As String) As String
    CleanUrl = Trim(url)
    CleanUrl = Replace(CleanUrl, "&amp;", "&")
End Function

' -------------------------------------------------------
' HTTP GET 요청으로 HTML 가져오기
' 캐시가 있으면 캐시에서 반환 (같은 URL 중복 요청 방지)
' -------------------------------------------------------
Private Function FetchUrl(url As String) As String
    ' 캐시 확인
    If htmlCache.Exists(url) Then
        FetchUrl = htmlCache(url)
        Exit Function
    End If

    On Error GoTo ErrHandler

    Dim http As Object
    Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")

    ' 타임아웃 설정 (밀리초): resolve, connect, send, receive
    ' 수백 개 함수를 동시에 돌릴 때 타임아웃을 걸어서 무한 대기 방지
    http.setTimeouts 5000, 5000, 10000, 15000

    http.Open "GET", url, False
    http.setRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    http.send

    If http.Status <> 200 Then
        FetchUrl = "Error: HTTP " & http.Status
        Set http = Nothing
        Exit Function
    End If

    ' 응답 디코딩 (한글 깨짐 방지)
    FetchUrl = DecodeResponse(http)

    ' 캐시 저장
    If Not htmlCache.Exists(url) Then
        htmlCache.Add url, FetchUrl
    End If

    Set http = Nothing
    Exit Function

ErrHandler:
    FetchUrl = "Error: " & Err.Description
End Function

' -------------------------------------------------------
' HTTP 응답 인코딩 처리
' Content-Type 헤더에서 charset을 감지하여 올바르게 디코딩
' (한글 페이지의 UTF-8, EUC-KR 등 자동 처리)
' -------------------------------------------------------
Private Function DecodeResponse(http As Object) As String
    On Error GoTo UseResponseText

    ' Content-Type 헤더에서 charset 추출
    Dim charset As String
    charset = DetectCharset(http)

    ' ADODB.Stream으로 바이너리 -> 텍스트 변환
    Dim stream As Object
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 1  ' adTypeBinary
    stream.Open
    stream.Write http.responseBody
    stream.Position = 0
    stream.Type = 2  ' adTypeText
    stream.charset = charset
    DecodeResponse = stream.ReadText
    stream.Close
    Set stream = Nothing
    Exit Function

UseResponseText:
    ' ADODB 실패 시 기본 responseText 사용
    DecodeResponse = http.responseText
End Function

' -------------------------------------------------------
' Content-Type 헤더에서 charset 감지
' 예: "text/html; charset=utf-8" -> "UTF-8"
' -------------------------------------------------------
Private Function DetectCharset(http As Object) As String
    On Error GoTo UseDefault

    Dim contentType As String
    contentType = LCase(http.getResponseHeader("Content-Type"))

    Dim pos As Long
    pos = InStr(contentType, "charset=")
    If pos > 0 Then
        DetectCharset = Mid(contentType, pos + 8)
        ' 세미콜론 이후 제거
        pos = InStr(DetectCharset, ";")
        If pos > 0 Then DetectCharset = Left(DetectCharset, pos - 1)
        ' 따옴표 제거
        DetectCharset = Replace(DetectCharset, """", "")
        DetectCharset = Replace(DetectCharset, "'", "")
        DetectCharset = Trim(DetectCharset)
        If DetectCharset <> "" Then Exit Function
    End If

UseDefault:
    DetectCharset = "UTF-8"
End Function

' -------------------------------------------------------
' HTML에서 특정 ID의 div 텍스트 추출
' htmlfile COM 객체로 DOM 파싱 후 getElementById 사용
' -------------------------------------------------------
Private Function ExtractDivText(html As String, divId As String) As String
    On Error GoTo ErrHandler

    ' 빠른 사전 검사: HTML에 divId가 없으면 파싱 생략
    If InStr(1, html, divId, vbTextCompare) = 0 Then
        ExtractDivText = ""
        Exit Function
    End If

    Dim doc As Object
    Set doc = CreateObject("htmlfile")

    ' HTML 파싱
    doc.Open
    doc.Write html
    doc.Close

    ' div 요소 찾기
    Dim elem As Object
    Set elem = doc.getElementById(divId)

    If Not elem Is Nothing Then
        ExtractDivText = Trim(elem.innerText)
    Else
        ExtractDivText = ""
    End If

    Set doc = Nothing
    Exit Function

ErrHandler:
    ExtractDivText = ""
End Function

' -------------------------------------------------------
' AJAX 컨텐츠 가져오기
' 알라딘 등 동적 로딩 페이지에서 AJAX로 로딩되는 컨텐츠를 가져옴
'
' 동작 원리 (알라딘 기준):
'   메인 페이지 HTML에 <div id="8926162893_Introduce"> 같은
'   빈 div가 있고, JavaScript가 AJAX로 내용을 채움.
'   이 함수는 그 AJAX URL을 직접 호출하여 컨텐츠를 가져옴.
'
' AJAX URL 패턴:
'   /shop/product/getContents.aspx?ISBN={isbn}&name={section}&type=0
' -------------------------------------------------------
Private Function FetchAjaxContent(mainHtml As String, mainUrl As String) As String
    On Error GoTo ErrHandler

    FetchAjaxContent = ""

    ' ISBN 추출 (예: id="8926162893_Introduce"에서 8926162893)
    Dim isbn As String
    isbn = ExtractIsbn(mainHtml)
    If isbn = "" Then Exit Function

    ' 베이스 URL 결정
    Dim baseUrl As String
    baseUrl = ExtractBaseUrl(mainUrl)
    If baseUrl = "" Then Exit Function

    ' AJAX 컨텐츠 섹션 목록 (우선순위순)
    ' - Introduce: 목차(div_TOC_All), 책소개 등
    ' - ShopInfo: 상품정보
    ' - AuthorInfo: 저자정보
    ' - PublisherDesc: 출판사서평
    Dim sections As Variant
    sections = Array("Introduce", "ShopInfo", "AuthorInfo", "PublisherDesc", "AladdinReview")

    Dim i As Long
    For i = LBound(sections) To UBound(sections)
        Dim sectionUrl As String
        sectionUrl = baseUrl & "/shop/product/getContents.aspx?ISBN=" & isbn & "&name=" & sections(i) & "&type=0"

        Dim sectionHtml As String
        sectionHtml = FetchUrl(sectionUrl)

        ' 에러 응답이 아니고 유효한 컨텐츠인 경우 반환
        If Left(sectionHtml, 6) <> "Error:" And Len(sectionHtml) > 0 Then
            FetchAjaxContent = FetchAjaxContent & sectionHtml
        End If
    Next i

    Exit Function

ErrHandler:
    FetchAjaxContent = ""
End Function

' -------------------------------------------------------
' 메인 HTML에서 ISBN 추출
' div id 패턴: "{isbn}_{섹션명}" (예: "8926162893_Introduce")
' 정규식으로 숫자+_+알파벳 패턴을 찾아 ISBN 부분 추출
' -------------------------------------------------------
Private Function ExtractIsbn(html As String) As String
    On Error GoTo ErrHandler

    Dim re As Object
    Set re = CreateObject("VBScript.RegExp")
    re.Pattern = "id=""(\d{10,13})_(?:Introduce|AladdinReview|ShopInfo|AuthorInfo)"""
    re.Global = False
    re.IgnoreCase = True

    Dim matches As Object
    Set matches = re.Execute(html)

    If matches.Count > 0 Then
        ExtractIsbn = matches(0).SubMatches(0)
    Else
        ExtractIsbn = ""
    End If

    Set re = Nothing
    Exit Function

ErrHandler:
    ExtractIsbn = ""
End Function

' -------------------------------------------------------
' URL에서 베이스 URL 추출
' 예: "https://www.aladin.co.kr/shop/wproduct.aspx?..." -> "https://www.aladin.co.kr"
' -------------------------------------------------------
Private Function ExtractBaseUrl(url As String) As String
    On Error GoTo ErrHandler

    ' "://" 이후 첫 번째 "/" 위치 찾기
    Dim protocolEnd As Long
    protocolEnd = InStr(url, "://")
    If protocolEnd = 0 Then
        ExtractBaseUrl = ""
        Exit Function
    End If

    Dim pathStart As Long
    pathStart = InStr(protocolEnd + 3, url, "/")
    If pathStart = 0 Then
        ExtractBaseUrl = url
    Else
        ExtractBaseUrl = Left(url, pathStart - 1)
    End If

    Exit Function

ErrHandler:
    ExtractBaseUrl = ""
End Function

' -------------------------------------------------------
' 캐시 초기화 매크로
' 데이터를 새로 가져오고 싶을 때 실행
' (개발자 탭 > 매크로 > ClearHtmlCache 실행)
' -------------------------------------------------------
Public Sub ClearHtmlCache()
    Set htmlCache = Nothing
    Set resultCache = Nothing
    MsgBox "htmlTOC 캐시가 초기화되었습니다." & vbCrLf & _
           "셀을 다시 계산하면 데이터를 새로 가져옵니다." & vbCrLf & vbCrLf & _
           "전체 재계산: Ctrl+Alt+F9", vbInformation, "htmlTOC 캐시 초기화"
End Sub
