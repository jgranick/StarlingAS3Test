package {
	
	
	import openfl.display.Stage;
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.rendering.VertexDataFormat;
	
	
	public class Main {
		
		
		public function Main () {
			
			trace (starling.rendering.VertexDataFormat);
			
			var quad:Quad = new Quad (100, 100);
			
			var format:VertexDataFormat = new VertexDataFormat ();
			trace (format);
			
			var stage:Stage = new Stage (320, 480, 0xFFFFFF);
			var content:HTMLDivElement = document.getElementById ("openfl-content") as HTMLDivElement;
			content.appendChild (stage.element);
			
		}
		
		
	}
	
	
}