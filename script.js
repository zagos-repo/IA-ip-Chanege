/*(document)Â£ Zakarya Â© 2020*/
$(document).ready(function(){
               
               function getdata(){
                 $.ajax({
                       url:"getdata.php",
                       type:"POST",
                       success:function(response){
                           $('#chatbox').html(response);
                       }  
                   });
                   $('#chatbox').animate({scrollTop:"1800000000" },4500);
               }
               $('#sendbtn').click(function(e){
                  e.preventDefault(); 
                   var name = $('#nickname').val();
                   var msg = $('#msg').val();
                   $.ajax({
                       url:"senddata.php",
                       type:"POST",
                       data:{n:name, m:msg},
                   });
                 $('#msg').val("");
                  getdata();
               }); 
               
               setInterval(function(){
                  getdata(); 
   
               },1500);
               
               
               
               
           });
           
           cument,
        text = element,
        range, selection;
      if (doc.body.createTextRange) {
        range = document.body.createTextRange();
        range.moveToElementText(text);
        range.select();
      } else if (window.getSelection) {
        selection = window.getSelection();
        range = document.createRange();
        range.selectNodeContents(text);
        selection.removeAllRanges();
        selection.addRange(range);
      }
    }

    function hasClass(ele, cls) {
      return !!ele.getAttribute('class').match(new RegExp('(\\s|^)' + cls + '(\\s|$)'));
    }

    window.onload = function() {
      var trigger = document.getElementById('cd-nav-trigger'),
        menu = document.getElementById('cd-main-nav'),
        menuItems = menu.getElementsByTagName('li');
      trigger.onclick = function toggleMenu() {
        if (hasClass(trigger, 'menu-is-open')) {
          trigger.setAttribute('class', 'cd-nav-trigger');
          menu.setAttribute('class', '');
        } else {
          trigger.setAttribute('class', 'cd-nav-trigger menu-is-open');
          menu.setAttribute('class', 'is-visible');
        }
      }

      for (var i = 0; i < menuItems.length; i++) {
        menuItems[i].onclick = function closeMenu() {
          trigger.setAttribute('class', 'cd-nav-trigger');
          menu.setAttribute('class', '');
        }
      }
    }
  </script>