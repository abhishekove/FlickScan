package com.dev.flutter_app_docscanner;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Point;
import android.util.Log;
import android.util.Pair;

import androidx.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Handler;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
//import me.pqpo.smartcropperlib.SmartCropper;

public class MainActivity extends FlutterActivity {
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),"getPoints").setMethodCallHandler(
                (call, result) -> {
                    if(call.method.equals("method")){
//                        byte[] byteArray =call.argument("image");
//                        assert byteArray != null;
//                        Bitmap bitmap=BitmapFactory.decodeByteArray(byteArray,0,byteArray.length);
//                        Point[] points=SmartCropper.scan(bitmap);
//
////                    Log.d("TAG", "configureFlutterEngine: "+((double)points[0].x/bitmap.getWidth()));
//                        double[] array=new double[10];
//                        for (int i=0;i<points.length;i++){
//                            int index=i*2;
//                            array[index]= (double) points[i].x;
////                        array[index]=array[index]/bitmap.getWidth();
//                            array[index+1]= (double) points[i].y;
////                        array[index+1]=array[index+1]/bitmap.getHeight();
//                        }
//                        array[8]=bitmap.getWidth();
//                        array[9]=bitmap.getHeight();
//                        result.success(array);
                    }
                    if(call.method.equals("cropped")){
//                        byte[] bytes=call.argument("image");
//                        assert bytes != null;
//                        Bitmap bitmap=BitmapFactory.decodeByteArray(bytes,0,bytes.length);
//                        int[] array=call.argument("points");
//                        Point[] points=new Point[4];
//                        for(int i=0;i<4;i++){
//                            int index=i*2;
//                            assert array != null;
//                            points[i]=new Point(array[index],array[index+1]);
//                        }
//                        bitmap=SmartCropper.crop(bitmap,points);
//                        ByteArrayOutputStream stream=new ByteArrayOutputStream();
//                        bitmap.compress(Bitmap.CompressFormat.PNG,100,stream);
//                        byte[] byteArray=stream.toByteArray();
//                        result.success(byteArray);

                    }
                }
        );
    }
}
