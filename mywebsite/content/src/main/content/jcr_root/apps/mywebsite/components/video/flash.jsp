<%--
  Copyright 1997-2010 Day Management AG
  Barfuesserplatz 6, 4001 Basel, Switzerland
  All Rights Reserved.

  This software is the confidential and proprietary information of
  Day Management AG, ("Confidential Information"). You shall not
  disclose such Confidential Information and shall use it only in
  accordance with the terms of the license agreement you entered into
  with Day.

  ==============================================================================

  HTML5 video component
  Flash Fallback

  ==============================================================================

--%><%@ include file="/apps/mywebsite/global.jsp" %><%
%><%@ page import="com.day.cq.dam.api.Asset,
                   com.day.cq.dam.api.Rendition,
                   java.util.Iterator, 
                   com.day.cq.analytics.sitecatalyst.Framework,  
                   com.day.cq.wcm.webservicesupport.Configuration,
                   com.day.cq.wcm.webservicesupport.ConfigurationManager,
                   com.day.cq.dam.commons.util.PrefixRenditionPicker,
                   com.day.cq.dam.video.VideoConstants" %><%

    final String DEFAULT_H264_PROFILE = "hq";
    final String DEFAULT_FLV_PROFILE = "flv";

    Asset asset = (Asset) request.getAttribute("video_asset"); // set by video.jsp
    
    String width = properties.get("width", currentStyle.get("width", "480"));
    String height = properties.get("height", currentStyle.get("height", "320"));
    String flashClass = currentStyle.get("flashClass", "");
    String wmode = currentStyle.get("wmode", "opaque");
    
    boolean noControls = currentStyle.get("noControls", false);
    boolean autoplay = currentStyle.get("autoplay", false);
    boolean loop = currentStyle.get("loop", false);
    
    String flashPlayer = currentStyle.get("flashPlayer", "flvfallback");
    if ("flvfallback".equals(flashPlayer) || "h264only".equals(flashPlayer)) {
        String flashProfile = currentStyle.get("flashProfile", DEFAULT_H264_PROFILE);
        Rendition rendition = asset.getRendition(new PrefixRenditionPicker(VideoConstants.RENDITION_PREFIX + flashProfile));
        if (rendition == null) {
%><cq:include script="fallback.jsp"/><%            
            return;
        }

        String strobeSWF = "/etc/clientlibs/foundation/video/swf/StrobeMediaPlayback.swf";
        String strobeVideo = "../../../../.." + rendition.getPath(); // strobe speciality: path must be relative to swf file
        String strobeFlashvars = currentStyle.get("strobeFlashvars", "");
        strobeFlashvars = "src=" + strobeVideo + (strobeFlashvars.length() > 0 ? "&" : "") + strobeFlashvars;
        strobeFlashvars += "&autoPlay=" + autoplay + "&loop=" + loop;
        if (noControls) {
            strobeFlashvars += "&controlBarMode=none";
        }

        String flashProfileFLV = currentStyle.get("flashProfileFLV", DEFAULT_FLV_PROFILE);
        Rendition flvRendition = asset.getRendition(new PrefixRenditionPicker(VideoConstants.RENDITION_PREFIX + flashProfileFLV));
        
        if ("flvfallback".equals(flashPlayer) && flvRendition != null) {
            
            String flvSWF = "/etc/clientlibs/foundation/video/swf/player_flv_maxi.swf";
            String flvVideo = flvRendition.getPath();
            String customFlvFlashvars = currentStyle.get("flvFlashvars", "margin=0&showvolume=1&showtime=1&showfullscreen=1");
            String flvFlashvars = "flv=" + flvVideo + "&width=" + width + "&height=" + height;
            if (customFlvFlashvars.length() > 0) {
                flvFlashvars += "&" + customFlvFlashvars;
            }
            flvFlashvars += "&autoplay=" + (autoplay ? "1" : "0") + "&loop=" + (loop ? "1" : "0");
            if (noControls) {
                flvFlashvars += "&showplayer=never";
            }
            
            String clsObj = flashClass.length() > 0 ? ", {\"class\": \"" + flashClass + "\"}" : "";
            
            String currentTime = ""+System.currentTimeMillis();
            String id = "cq-video-flash-alternate-" + currentTime;
            
%><cq:includeClientLib js="cq.swfobject" />
    <script> 
        var e = document.getElementById("<%= id %>");
        if (e) e.style.display = "block"; 
        
        var flashVersion = window.CQ_swfobject ? CQ_swfobject.getFlashPlayerVersion() : -1;
        if (flashVersion.major >= 10){
           CQ_swfobject.embedSWF("<%= strobeSWF %>", "<%= id %>", "<%= width %>", "<%= height %>", "10", "", false,
                                  {flashvars: "<%= strobeFlashvars %>&javascriptCallbackFunction=strobeTrackingCallback<%= currentTime %>", 
                                      allowFullScreen: "true", wmode: "<%= wmode %>"}<%= clsObj %>);
        } else if (flashVersion.major >= 7) {
            CQ_swfobject.embedSWF("<%= flvSWF %>", "<%= id %>", "<%= width %>", "<%= height %>", "7", "", false,
                                  {flashvars: "<%= flvFlashvars %>", allowFullScreen: "true"}<%= clsObj %>);
        }

        if (!trackingClipData || typeof trackingClipData != "object") {
            var trackingClipData = new Object();
        }
        trackingClipData["<%= id %>"] = new Object();
        trackingClipData["<%= id %>"].duration   = -1;
        trackingClipData["<%= id %>"].playhead   = 0;
        trackingClipData["<%= id %>"].source     = "<%= asset.getMetadataValue("dc:title")!= "" ? asset.getMetadataValue("dc:title") : asset.getName() %>";  
        trackingClipData["<%= id %>"].sourceFile = "<%= asset.getName() %>";
        trackingClipData["<%= id %>"].sourcePath = "<%= asset.getPath() %>";
        
        //video open flag
        var videoOpen = false;

        //send play event later to update the playhead on scrub events
        var delay = 1000;
    
        //clickstream cloud data to be send based on context mapping
        var CQ_data = new Object();

        function open<%= currentTime %>(){
            videoOpen = true; 
            
            CQ_data = new Object(); 
            CQ_data["length"]       = trackingClipData["<%= id %>"].duration;
            CQ_data["playerType"]   = "Strobe Media Playback";
            CQ_data["source"]       = trackingClipData["<%= id %>"].source;
            CQ_data["playhead"]     = trackingClipData["<%= id %>"].playhead;
            
            CQ_data["videoName"]     = trackingClipData["<%= id %>"].source;
            CQ_data["videoFileName"] = trackingClipData["<%= id %>"].sourceFile;
            CQ_data["videoFilePath"] = trackingClipData["<%= id %>"].sourcePath;
 
            CQ_Analytics.record({event: 'videoinitialize', values: CQ_data, componentPath: '<%=resource.getResourceType()%>' }); 
        }
        
        function play<%= currentTime %>(){
             if (trackingClipData["<%= id %>"].duration > 0) {
                if (!videoOpen) { 
                    open<%= currentTime %>();
                } else {

                    CQ_data = new Object();  
                    CQ_data["playhead"]     = trackingClipData["<%= id %>"].playhead - delay/1000; 
                    CQ_data["source"]       = trackingClipData["<%= id %>"].source;

                    CQ_Analytics.record({event: 'videoplay', values: CQ_data, componentPath: '<%=resource.getResourceType()%>' });
                }
            }
        }
        
        function pause<%= currentTime %>(){
            CQ_data = new Object();  
            CQ_data["playhead"]     = trackingClipData["<%= id %>"].playhead; 
            CQ_data["source"]       = trackingClipData["<%= id %>"].source;
            
            CQ_Analytics.record({event: 'videopause', values: CQ_data, componentPath: '<%=resource.getResourceType()%>' });
        }
        

        function strobeTrackingCallback<%= currentTime %>(playerId, state, obj) { 
                switch (state) {
                    case "durationchange": 
                        trackingClipData["<%= id %>"].duration = parseInt(obj.duration);
                        if (!videoOpen) {
                            open<%= currentTime %>();
                        }
                        break;
                    case "play": 
                        //send pause event befor delay play to fix scrub events for tracking
                        pause<%= currentTime %>();
                        setTimeout(play<%= currentTime %>, delay);
                        break;
                    case "timeupdate":
                        trackingClipData["<%= id %>"].playhead = parseInt(obj.currentTime);  
                        break;
                    case "pause":
                        pause<%= currentTime %>();
                        break;
                    case "complete":
                        CQ_data = new Object();  
                        CQ_data["playhead"]       = trackingClipData["<%= id %>"].playhead; 
                        CQ_data["source"]       = trackingClipData["<%= id %>"].source;
                        
                        CQ_Analytics.record({event: 'videoend', values: CQ_data, componentPath: '<%=resource.getResourceType()%>' });

                        videoOpen = false; 
                        break;
                    default:
                        // do nothing if other events are triggered
                        break;
                }
        }
    </script>
    
    
    <div id="<%= id %>" class="cq-video-flash-alternate" style="display:none;">
        <cq:include script="fallback.jsp"/>
    </div>
    <noscript>
        <object class="<%= flashClass %>" type="application/x-shockwave-flash" data="<%= flvSWF %>" width="<%= width %>" height="<%= height %>">
            <param name="movie" value="<%= flvSWF %>" />
            <param name="allowFullScreen" value="true" />
            <param name="wmode" value="<%= wmode %>" />
            <param name="flashvars" value="<%= flvFlashvars %>" />
            <cq:include script="fallback.jsp"/>
        </object>
    </noscript>
<%
        
        } else /* if ("h264only".equals(flashPlayer)) */ {
        
%>
    <object class="<%= flashClass %>" type="application/x-shockwave-flash" data="<%= strobeSWF %>" width="<%= width %>" height="<%= height %>">
        <param name="movie" value="<%= strobeSWF %>" />
        <param name="allowFullScreen" value="true" />
        <param name="wmode" value="<%= wmode %>" />
        <param name="flashvars" value="<%= strobeFlashvars %>" />
        <cq:include script="fallback.jsp"/>
    </object>
<%
        }
        
    } else /* if ("custom".equals(flashPlayer)) */ {
        
        String flashProfileCustom = currentStyle.get("flashProfileCustom", "hq");
        Rendition customRendition = asset.getRendition(new PrefixRenditionPicker(VideoConstants.RENDITION_PREFIX + flashProfileCustom));
        
        String customSWF = currentStyle.get("customSWF", "");
        String customVideo = customRendition != null ? customRendition.getPath() : "";
        String customFlashvars = currentStyle.get("customFlashvars", "");

        String customMovieFlashvar = currentStyle.get("customMovieFlashvar", String.class);
        if (customMovieFlashvar != null) {
            customFlashvars = customFlashvars + (customFlashvars.length() > 0 ? "&":"") + customMovieFlashvar + "=" + customVideo;
        }
        String customWidthFlashvar = currentStyle.get("customWidthFlashvar", String.class);
        if (customWidthFlashvar != null) {
            customFlashvars = customFlashvars + (customFlashvars.length() > 0 ? "&":"") + customWidthFlashvar + "=" + width;
        }
        String customHeightFlashvar = currentStyle.get("customHeightFlashvar", String.class);
        if (customHeightFlashvar != null) {
            customFlashvars = customFlashvars + (customFlashvars.length() > 0 ? "&":"") + customHeightFlashvar + "=" + height;
        }
%>
        <object class="<%= flashClass %>" type="application/x-shockwave-flash" data="<%= customSWF %>" width="<%= width %>" height="<%= height %>">
            <param name="movie" value="<%= customSWF %>" />
            <param name="allowFullScreen" value="true" />
            <param name="flashvars" value="<%= customFlashvars %>" />
            <cq:include script="fallback.jsp"/>
        </object>
<%
    }
%>