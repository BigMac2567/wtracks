<%@ page import="java.util.*, java.io.*, javax.servlet.jsp.JspWriter, java.net.URLEncoder, java.net.URLDecoder, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager, javax.jdo.Query, org.apache.commons.lang3.StringEscapeUtils" %><%@ include file="userid.jsp" %><%!

  void listTracks(HttpSession session, PersistenceManager pm, JspWriter out, String scope, String hostURL) throws IOException {
//System.out.println("list");
    String query = "select from " + GPX.class.getName(); 
    boolean publicList = scope.equals("all");
    Object param;
    if (publicList) {
      query += " where sharedMode==qsharedmode parameters int qsharedmode";
      param = new Integer(GPX.SHARED_PUBLIC); 
    } else {
      query += " where owner==qowner parameters String qowner";
      param = getUserID(session); 
    }
    query += " order by name asc";
//System.out.println("list query: " + query);
    List<GPX> tracks = (List<GPX>) pm.newQuery(query).execute(param);
    for (GPX track : tracks) {
      String name = track.getName();
      String id = track.getId();
      int sharedMode = track.getSharedMode();
//System.out.println("track: " + track);
      String linktxt = name.length() > 50 ? name.substring(0,47) + "..." : name;
      out.println("<div class='atrackentry' name='" + StringEscapeUtils.escapeXml10(name) + "'>");
      if (!publicList) {
        out.println("<a href='#' onclick='delete_track(\"" + StringEscapeUtils.escapeXml10(name) + "\", \"" + URLEncoder.encode(id) + "\")' title='Delete this track'><img src='img/delete.gif' title='Delete this track' alt='delete' style='border:0px'></a>&nbsp;");
      }
      String qparam = "?id=" + URLEncoder.encode(id);
      out.print("<a href='." + qparam + "' ");
      out.print(" onclick='wt_loadUserGPX(\"" + URLEncoder.encode(id) + "\"); return false; ' >");
      out.println(linktxt + "</a>");
      if (sharedMode == GPX.SHARED_PUBLIC) {
        out.println("<img src='img/share.gif' title='Public - Anyone can see and read this track' alt='public' style='border:0px'>");
      } else if (sharedMode == GPX.SHARED_LINK) {
        out.println("<img src='img/link.png' title='Shareable - you can share this link' alt='shareable' style='border:0px'>");
      }
      out.println("<a target='_blank' href='http://chart.apis.google.com/chart?cht=qr&chs=400x400&chld=L&choe=UTF-8&chl="+URLEncoder.encode(hostURL + qparam)+"'><img src='img/qrcode.png' title='Show QRCode' alt='QRCode' style='border:0px'></a>");
      out.println("</div>");
    }
  }
  
%><%
//System.out.println("starting");
  String scope = request.getParameter("scope");
  String id = request.getParameter("id");
  String delete = request.getParameter("delete");
  String scheme = request.isSecure() ? "https" : "http";
  String hostURL = scheme + "://" + request.getServerName() + "/";
/**
  System.out.println("scope: " + scope);
  System.out.println("Logged UserID: " + getUserID(session));
  System.out.println("id: " + id);
  System.out.println("delete: " + delete);
/**/
  if (delete != null) {

    // get track
    PersistenceManager pm = PMF.get().getPersistenceManager();
    GPX track = getTrack(session, pm, delete);
    if (track == null) {
      response.sendError(HttpServletResponse.SC_NOT_FOUND, "This track does not exist");
      return;
    }
    // check logged user is owner
    if (!isUser(session, track.getOwner())) {
      // not authorized
      response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Not authorized to delete this track");
      return;
    }

    pm.deletePersistent(track);

    listTracks(session, pm, out, scope, hostURL);

} else if (id == null) {

    // list
    PersistenceManager pm = PMF.get().getPersistenceManager();
    listTracks(session, pm, out, scope, hostURL);
    
} else if (id != null) {

    PersistenceManager pm = PMF.get().getPersistenceManager();
    GPX track = getTrack(session, pm, id);
    if (track == null) {
      response.sendError(HttpServletResponse.SC_NOT_FOUND, "This track does not exist");
      return;
    }

    response.setContentType("text/xml");
    out.println(track.getGpx());

}
%>
