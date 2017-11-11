;;; ---------------------------------------------------------
;;; Based on: https://ogbe.net/blog/blogging_with_org.html
;;;

;;; ---------------------------------------------------------
;;; General information
;;;
(setq bookhacker-github-username "bookhacker")

(setq my-blog-extra-head "<link rel=\"stylesheet\" href=\"../css/stylesheet.css\" />")

;;; ---------------------------------------------------------
;;;
(defun my-blog-get-preview (file)
  "The comments in FILE have to be on their own lines, prefereably before and after paragraphs."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((beg (+ 1 (re-search-forward "^#\\+BEGIN_PREVIEW$")))
          (end (progn (re-search-forward "^#\\+END_PREVIEW$")
                      (match-beginning 0))))
      (buffer-substring beg end))))

;;; ---------------------------------------------------------
;;; 
(defun my-blog-sitemap (project &optional sitemap-filename)
  "Generate the sitemap for my blog."
  (let* ((project-plist (cdr project))
         (dir (file-name-as-directory
               (plist-get project-plist :base-directory)))
         (localdir (file-name-directory dir))
         (exclude-regexp (plist-get project-plist :exclude))
         (files (nreverse
                 (org-publish-get-base-files project exclude-regexp)))
         (sitemap-filename (concat dir (or sitemap-filename "sitemap.org")))
         (sitemap-sans-extension
          (plist-get project-plist :sitemap-sans-extension))
         (visiting (find-buffer-visiting sitemap-filename))
         file sitemap-buffer)
    (with-current-buffer
        (let ((org-inhibit-startup t))
          (setq sitemap-buffer
                (or visiting (find-file sitemap-filename))))
      (erase-buffer)
      ;; loop through all of the files in the project
      (while (setq file (pop files))
        (let ((fn (file-name-nondirectory file))
              (link ;; changed this to fix links. see postprocessor.
               (file-relative-name file (file-name-as-directory
                                         (expand-file-name (concat (file-name-as-directory dir) "..")))))
              (oldlocal localdir))
          (when sitemap-sans-extension
            (setq link (file-name-sans-extension link)))
          ;; sitemap shouldn't list itself
          (unless (equal (file-truename sitemap-filename)
                         (file-truename file))
            (let (;; get the title and date of the current file
		  (title (org-publish-format-file-entry "%t" file project-plist))
		  (date (org-publish-format-file-entry "%d" file project-plist))
		  ;; (date (org-publish-find-date file))
		  ;; (date (plist-get env :date))
                  ;; get the preview section from the current file
                  (preview (my-blog-get-preview file))
                  (regexp "\\(.*\\)\\[\\([^][]+\\)\\]\\(.*\\)"))
              ;; insert a horizontal line before every post, kill the first one
              ;; before saving
              (insert "-----\n")
              (cond ((string-match-p regexp title)
                     (string-match regexp title)
                     ;; insert every post as headline
                     (insert (concat"* " (match-string 1 title)
                                    "[[file:" link "]["
                                    (match-string 2 title)
                                    "]]" (match-string 3 title) "\n")))
                    (t (insert (concat "* [[file:" link "][" title "]]\n"))))
              ;; add properties for `ox-rss.el' here
              (let ((rss-permalink (concat (file-name-sans-extension link) ".html"))
                    (rss-pubdate (format-time-string
                                  (car org-time-stamp-formats)
                                  (org-publish-find-date file))))
                (org-set-property "RSS_PERMALINK" rss-permalink)
                (org-set-property "PUBDATE" rss-pubdate))
              ;; insert the date, preview, & read more link
              ;; (insert (concat date "\n\n"))
	      (insert (concat "#+HTML: <div class=\"post-date\">\nVeröffentlicht: " date "\n#+HTML: </div>\n\n"))
              (insert preview)
              (insert (concat "[[file:" link "][Weiterlesen...]]\n"))))))
      ;; kill the first hrule to make this look OK
      (goto-char (point-min))
      (let ((kill-whole-line t)) (kill-line))
      (goto-char (point-min))
      (setq sitemap-title (plist-get project-plist :sitemap-title))
      (insert (format "#+TITLE: %s\n\n" sitemap-title))
      (save-buffer))
    (or visiting (kill-buffer sitemap-buffer))))

;;; ---------------------------------------------------------
;;;
(defun my-blog-articles-postprocessor ()
  "Massage the sitemap file and move it up one directory.

for this to work, we have already fixed the creation of the
relative link in the sitemap-publish function"
  (let* ((sitemap-fn (concat (file-name-sans-extension (plist-get project-plist :sitemap-filename)) ".html"))
         (sitemap-olddir (plist-get project-plist :publishing-directory))
         (sitemap-newdir (expand-file-name (concat (file-name-as-directory sitemap-olddir) "..")))
         (sitemap-oldfile (expand-file-name sitemap-fn sitemap-olddir))
         (sitemap-newfile (expand-file-name (concat (file-name-as-directory sitemap-newdir) sitemap-fn))))
    (with-temp-buffer
      (goto-char (point-min))
      (insert-file-contents sitemap-oldfile)
      ;; massage the sitemap if wanted

      ;; delete the old file and write the correct one
      (delete-file sitemap-oldfile)
      (write-file sitemap-newfile))))

;;; ---------------------------------------------------------
;;; 
(setq org-publish-project-bookhacker
      '(("bookhacker" :components ("bookhacker-articles" "bookhacker-pages" "bookhacker-static"))
	("bookhacker-articles"
 	 :base-directory "~/org/websites/bookhacker.org/org-files/blog/"
	 :base-extension "org"
	 :publishing-directory "~/org/websites/bookhacker.org/public_html/blog/"
	 :completion-function my-blog-articles-postprocessor
	 :recursive t
	 :publishing-function org-html-publish-to-html
	 :with-author t
	 :with-creator nil
	 :with-date t
	 :headline-level 4
	 :section-numbers nil
	 :with-toc nil
	 :with-drawers t
	 :html-link-home "/"
	 :html-preamble
	 "<header id=\"banner\">
<div class=\"wrapper\">
  <h1><a href=\"https://bookhacker.org\">bookhacker.org</a></h1>
  <nav><ul>
    <li><a href=\"https://bookhacker.org/datenschutz.html\">Datenschutz</a></li>
    <li><a href=\"https://bookhacker.org/impressum.html\">Impressum</a></li>
  </ul></nav>
</div>
</header>"	 
	 :html-postamble "<footer>
<div class=\"wrapper\">
	 <h2 class=\"footer-heading\">bookhacker.org</h2>
<div class=\"footer-left\">
<ul class=\"contact-list\">
<li>bookhacker.org</li>
<li><a href=\"mailto:kontakt@bookhacker.org\">kontakt@bookhacker.org</a></li>
</ul>
</div>
<div class=\"footer-center\">
<ul class=\"contact-list\">
<li><span class=\"icon\"><svg viewBox=\"0 0 16 16\" width=\"16px\" height=\"16px\"><path fill=\"#828282\" d=\"M7.999,0.431c-4.285,0-7.76,3.474-7.76,7.761 c0,3.428,2.223,6.337,5.307,7.363c0.388,0.071,0.53-0.168,0.53-0.374c0-0.184-0.007-0.672-0.01-1.32 c-2.159,0.469-2.614-1.04-2.614-1.04c-0.353-0.896-0.862-1.135-0.862-1.135c-0.705-0.481,0.053-0.472,0.053-0.472 c0.779,0.055,1.189,0.8,1.189,0.8c0.692,1.186,1.816,0.843,2.258,0.645c0.071-0.502,0.271-0.843,0.493-1.037 C4.86,11.425,3.049,10.76,3.049,7.786c0-0.847,0.302-1.54,0.799-2.082C3.768,5.507,3.501,4.718,3.924,3.65 c0,0,0.652-0.209,2.134,0.796C6.677,4.273,7.34,4.187,8,4.184c0.659,0.003,1.323,0.089,1.943,0.261 c1.482-1.004,2.132-0.796,2.132-0.796c0.423,1.068,0.157,1.857,0.077,2.054c0.497,0.542,0.798,1.235,0.798,2.082 c0,2.981-1.814,3.637-3.543,3.829c0.279,0.24,0.527,0.713,0.527,1.437c0,1.037-0.01,1.874-0.01,2.129 c0,0.208,0.14,0.449,0.534,0.373c3.081-1.028,5.302-3.935,5.302-7.362C15.76,3.906,12.285,0.431,7.999,0.431z\"/></svg></span><span class=\"username\"><a href=\"https://github.com/bookhacker\" target=\"_blank\">bookhacker</span></li>
</ul>
</div>
<div class=\"footer-right\">
<p>Kompjuta Tekknolodschie</p>
</div>
</div>
</footer>"
	 :html-head nil ;; cleans up anything that would have been in there.
	 :html-head-extra "<link rel=\"stylesheet\" href=\"css/stylesheet.css\" />"
	 :html-head-include-default-style nil
	 :html-head-include-scripts nil
	 :auto-preamble t
	 ;; sitemap - list of blog articles
         :auto-sitemap t
	 :sitemap-title "Kompjuta Tekknolodschie"
	 :sitemap-filename "index.org"
         ;; custom sitemap generator function
         :sitemap-function my-blog-sitemap
         :sitemap-sort-files anti-chronologically
         :sitemap-date-format "%d.%m.%Y")
	("bookhacker-pages"
 	 :base-directory "~/org/websites/bookhacker.org/org-files/"
	 :base-extension "org"
	 :publishing-directory "~/org/websites/bookhacker.org/public_html/"
	 :recursive nil
	 :publishing-function org-html-publish-to-html
	 :with-author t
	 :with-creator nil
	 :with-date t
	 :headline-level 4
	 :section-numbers nil
	 :with-toc nil
	 :with-drawers t
	 :html-link-home "/"
	 :html-preamble
	 "<header id=\"banner\">
<div class=\"wrapper\">
  <h1><a href=\"https://bookhacker.org\">bookhacker.org</a></h1>
  <nav><ul>
    <li><a href=\"https://bookhacker.org/datenschutz.html\">Datenschutz</a></li>
    <li><a href=\"https://bookhacker.org/impressum.html\">Impressum</a></li>
  </ul></nav>
</div>
</header>"	 
	 :html-postamble
	 "<footer>
<div class=\"wrapper\">
	 <h2 class=\"footer-heading\">bookhacker.org</h2>
<div class=\"footer-left\">
<ul class=\"contact-list\">
<li>bookhacker.org</li>
<li><a href=\"mailto:kontakt@bookhacker.org\">kontakt@bookhacker.org</a></li>
</ul>
</div>
<div class=\"footer-right\">
<p>Kompjuta Tekknolodschie</p>
</div>
</div>
</footer>")	
	("bookhacker-static"
	 :base-directory "~/org/websites/bookhacker.org/org-files/"
	 :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf\\|svg"
	 :publishing-directory "~/org/websites/bookhacker.org/public_html/"
	 :recursive t
	 :publishing-function org-publish-attachment)))
