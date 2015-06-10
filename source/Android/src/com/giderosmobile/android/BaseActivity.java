package com.giderosmobile.android;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.UnknownHostException;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

/**
 * Base Activity with some common check methods.
 * 
 * @author jdbc
 *
 */
public abstract class BaseActivity extends Activity {
	
	private static final String MSG_INTERNET_ENABLED = "To Use this Application, Internet must be enabled.";
	private static final String MSG_ADS_WORKING = "To Use this Application, Ads must be working.";
	
	/**
	 * Checks if phone is online. Otherwise finish the application.
	 * 
	 */
	public boolean check_online() {
	    boolean haveConnectedWifi = false;
	    boolean haveConnectedMobile = false;

	    ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
	    NetworkInfo[] netInfo = cm.getAllNetworkInfo();
	    for (NetworkInfo ni : netInfo) {
	        if (ni.getTypeName().equalsIgnoreCase("WIFI"))
	            if (ni.isConnected())
	                haveConnectedWifi = true;
	        if (ni.getTypeName().equalsIgnoreCase("MOBILE"))
	            if (ni.isConnected())
	                haveConnectedMobile = true;
	    }

	    boolean result = haveConnectedWifi==false && haveConnectedMobile==false;
	    if(result){
	    	AlertDialog.Builder builder = new AlertDialog.Builder(this);
	        builder.setMessage(MSG_INTERNET_ENABLED)
	                .setCancelable(false)
	                .setPositiveButton("OK", new DialogInterface.OnClickListener() {

	                    public void onClick(DialogInterface dialog, int which) {
	                       finish();
	                    }
	                });
	            AlertDialog alert = builder.create();
	            alert.show();
	    }
	    
	    return result;
	}
	
	/**
	 * Checks if AdBlock is working. In this case application will be closed.
	 * 
	 */
	public boolean check_adblock() {
	    BufferedReader in = null;
	    boolean result = true;

	    try 
	    {
	        in = new BufferedReader(new InputStreamReader(
	                new FileInputStream("/etc/hosts")));
	        String line;

	        while ((line = in.readLine()) != null)
	        {
	            if (line.contains("admob"))
	            {
	                result = false;
	                break;
	            }
	        }
	    } catch (UnknownHostException e) { }
	      catch (IOException e) {e.printStackTrace();}  

	    if(!result){
	    	AlertDialog.Builder builder = new AlertDialog.Builder(this);
	        builder.setMessage(MSG_ADS_WORKING)
	                .setCancelable(false)
	                .setPositiveButton("OK", new DialogInterface.OnClickListener() {

	                    public void onClick(DialogInterface dialog, int which) {
	                       finish();
	                    }
	                });
	            AlertDialog alert = builder.create();
	            alert.show();
	    }
	    
	    return result;
	}
}
