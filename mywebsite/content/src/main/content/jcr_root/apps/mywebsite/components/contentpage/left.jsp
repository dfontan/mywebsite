<%@include file="/apps/mywebsite/global.jsp"%><%
%><%@ page import="com.day.text.Text"%><%
%><% String docroot = currentDesign.getPath(); 
String home = Text.getAbsoluteParent(currentPage.getPath(), 2);%>

<div class="left">
<div><cq:include path="logo" resourceType="mywebsite/components/logo" /></div>
<div><cq:include path="newslist" resourceType="mywebsite/components/listchildren" /></div>
<div><div class="form_1">
     <form class="geo" action="<%= home %>/toolbar/search.html" id="form" >
          <p>
               <input class="geo" type="text" name="q"><br> 
               <a href="<%= home %>/toolbar/search.html" class="link_1">advanced search</a> 
          </p>
     </form>
</div></div>
</div>