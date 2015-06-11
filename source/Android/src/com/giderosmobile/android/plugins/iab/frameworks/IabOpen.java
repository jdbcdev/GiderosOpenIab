package com.giderosmobile.android.plugins.iab.frameworks;

import java.io.UnsupportedEncodingException;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.List;
import java.util.Set;

import org.onepf.oms.OpenIabHelper;
import org.onepf.oms.appstore.googleUtils.IabHelper.OnIabPurchaseFinishedListener;
import org.onepf.oms.appstore.googleUtils.IabHelper.OnConsumeFinishedListener;
import org.onepf.oms.appstore.googleUtils.IabHelper.OnIabSetupFinishedListener;
import org.onepf.oms.appstore.googleUtils.IabHelper.QueryInventoryFinishedListener;
import org.onepf.oms.appstore.googleUtils.IabResult;
import org.onepf.oms.appstore.googleUtils.Inventory;
import org.onepf.oms.appstore.googleUtils.Purchase;

import com.giderosmobile.android.plugins.iab.Iab;
import com.giderosmobile.android.plugins.iab.IabInterface;

import org.onepf.oms.appstore.googleUtils.SkuDetails;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.util.SparseArray;

/**
 * 
 * 
 * @author jdbc
 *
 */
public class IabOpen implements IabInterface, 
									OnIabPurchaseFinishedListener, 
									OnConsumeFinishedListener, 
									OnIabSetupFinishedListener,
									QueryInventoryFinishedListener
{
	
	private static final List<String> APP_STORES = Arrays.asList(OpenIabHelper.NAME_SLIDEME,
																	 OpenIabHelper.NAME_APPLAND,
																	 OpenIabHelper.NAME_YANDEX,
																	 OpenIabHelper.NAME_GOOGLE
																	 );
											
	private static WeakReference<Activity> sActivity;
	private OpenIabHelper mHelper;
	private boolean wasChecked = false;
	private int sdkAvailable = -1;
	
	public static Boolean isInstalled(){
			
		/*if (Iab.isPackageInstalled("com.slideme.sam.manager"))
			return true;*/
		
		return true;
	}
	
	@Override
	public void onCreate(WeakReference<Activity> activity) {
		sActivity = activity;
	}

	@Override
	public void onDestroy() {
		if (mHelper != null) 
			mHelper.dispose();
		mHelper = null;
	}
	
	@Override
	public void onStart() {
	}

	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		mHelper.handleActivityResult(requestCode, resultCode, data);
	}

	@Override
	public void init(Object parameters) {
		
		SparseArray<byte[]> p = (SparseArray<byte[]>)parameters;
		try {
			
			OpenIabHelper.Options.Builder builder = new OpenIabHelper.Options.Builder();
			
			//Pair number of (key, value)
			for (int i=0; i < p.size(); i = i + 2)
			{
				String appStore = new String(p.get(i), "UTF-8");
				String appKey = new String(p.get(i + 1), "UTF-8");
				
				if (appStore!=null && APP_STORES.contains(appStore)){
					builder.addStoreKey(appStore, appKey);
				}
				
			}
			//int size = p.size();
			
			//.addPreferredStoreName(OpenIabHelper.NAME_SLIDEME)
			//.addAvailableStoreNames(OpenIabHelper.NAME_SLIDEME)
			builder.setStoreSearchStrategy(OpenIabHelper.Options.SEARCH_STRATEGY_INSTALLER_THEN_BEST_FIT)
			//.setVerifyMode(OpenIabHelper.Options.VERIFY_SKIP);
				.setVerifyMode(OpenIabHelper.Options.VERIFY_EVERYTHING);
			mHelper = new OpenIabHelper(sActivity.get(), builder.build());
			
		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
		}
								
	}
		
	@Override
	public void check() {
		if(sdkAvailable == 1)
			Iab.available(this);
		else if(sdkAvailable == 0)
			Iab.notAvailable(this);
		else
			wasChecked = true;
	}
	
	@Override
	public void startSetup()
	{
		mHelper.startSetup(this);
	}
	
	@Override
	public void request(Hashtable<String, String> products) {
				
		List<String> skuList = new ArrayList<String>();
    	Enumeration<String> e = products.keys();
		while(e.hasMoreElements())
		{
			String prodName = e.nextElement();
        	skuList.add(products.get(prodName));
        }
		
        mHelper.queryInventoryAsync(true, skuList, this);
	}

	@Override
	public void purchase(String productId) {
		
		int RC_REQUEST = 10001;
		String payload = "";
		
		mHelper.launchPurchaseFlow(sActivity.get(), productId, RC_REQUEST, (OnIabPurchaseFinishedListener) this, payload);
	}

	@Override
	public void restore() {
		
		mHelper.queryInventoryAsync(new IabOpenPurchased(this));
	}

	@Override
	public void onIabPurchaseFinished(IabResult result, Purchase info) {
		
		if (result.isFailure()) {
			Iab.purchaseError(this, result.getMessage());
			return;
		}
		if(Iab.isConsumable(info.getSku(), this))
		{
			mHelper.consumeAsync(info, this);
		}
		else
		{
			Iab.purchaseComplete(this, info.getSku(), info.getOrderId());
		}
	}
		
	@Override
	public void onConsumeFinished(Purchase purchase, IabResult result) {
		if (result.isSuccess()) {
			Iab.purchaseComplete(this, purchase.getSku(), purchase.getOrderId());
	    }
	    else {
	    	Iab.purchaseError(this, result.getMessage());
	    }
		
	}

	@Override
	public void onIabSetupFinished(IabResult result) {
		if (result.isSuccess())
			 sdkAvailable = 1;
		 else
			 sdkAvailable = 0;
	     if(wasChecked)
	     {
	    	 if(sdkAvailable == 1)
	    		 Iab.available(this);
	    	 else
	    		 Iab.notAvailable(this);
	     }
		
	}

	@Override
	public void onQueryInventoryFinished(IabResult result, Inventory inventory) {
		if (result.isFailure()) {
			//Iab.productsError(this, "Request Failed");
			Iab.productsError(this, result.getMessage());
			return;
		}
		
		Hashtable<String, String> products = Iab.getProducts(this);
		SparseArray<Bundle> arr = new SparseArray<Bundle>();
		Enumeration<String> e = products.keys();
		int i = 0;
		while(e.hasMoreElements())
		{
			String prodName = e.nextElement();
			SkuDetails details = inventory.getSkuDetails(products.get(prodName));
        	if(details != null)
        	{
        		Bundle map = new Bundle();
        		map.putString("productId", products.get(prodName));
        		map.putString("title", details.getTitle());
        		map.putString("description", details.getDescription());
        		map.putString("price", details.getPrice());
        		arr.put(i, map);
        		i++;
        	}
        }
        Iab.productsComplete(this, arr);
		
	}
	
	/**
	 * Restore listener
	 * 
	 * @author jdbc
	 *
	 */
	class IabOpenPurchased implements QueryInventoryFinishedListener{
		IabOpen caller;
		public IabOpenPurchased(IabOpen iabOpen) {
			caller = iabOpen;
		}
		
		@Override
		public void onQueryInventoryFinished(IabResult result, Inventory inv) {
			if (result.isFailure()) {
				Iab.restoreError(caller, "Request Failed");
			}
			else
			{
				Hashtable<String, String> products = Iab.getProducts(caller);
				Enumeration<String> e = products.keys();
				while(e.hasMoreElements())
				{
					String prodName = e.nextElement();
					if(inv.hasPurchase(products.get(prodName)))
					{
						Purchase info = inv.getPurchase(products.get(prodName));
						Iab.purchaseComplete(caller, products.get(prodName), info.getOrderId());
					}
				}
				Iab.restoreComplete(caller);
			}
		}
	}
}
