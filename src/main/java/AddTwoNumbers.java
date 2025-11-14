import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;


public class AddTwoNumbers extends HttpServlet
{
  public void service(HttpServletRequest request, HttpServletResponse response) throws IOException
  {
       int i = Integer.parseInt(request.getParameter("num1"));
      int j = Integer.parseInt(request.getParameter("num2"));
           int total=i+j;
      PrintWriter out=response.getWriter();
      out.println("Result : "+total);
  }
}
