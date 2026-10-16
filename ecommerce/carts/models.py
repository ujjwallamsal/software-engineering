from decimal import Decimal
from django.db import models
from django.db.models.signals import m2m_changed, pre_save
from django.conf import settings
from products.models import Product

User = settings.AUTH_USER_MODEL

# Create your models here.
class CartManager(models.Manager):
    def new_or_get(self,request):
        cart_id = request.session.get("cart_id",None)
        qs      = self.get_queryset().filter(id=cart_id)
        if qs.count() == 1:
            new_obj  = False
            cart_obj = qs.first()
            if request.user.is_authenticated() and cart_obj.user is None:
                cart_obj.user = request.user
                cart_obj.save()
        else:
            cart_obj = self.model.objects.new(user=request.user)
            request.session['cart_id'] = cart_obj.id
            print(request.session.get('cart_id'))
            new_obj = True
        return cart_obj, new_obj
    
    def new(self,user=None):
        user_obj = None
        if user is not None:
            if user.is_authenticated():
                user_obj = user
        return self.model.objects.create(user=user_obj)
            
class Cart(models.Model):
    user        =   models.ForeignKey(User,null=True,blank=True)
    products    =   models.ManyToManyField(Product,blank=True)
    subtotal    =   models.DecimalField(default=0.00,max_digits=100,decimal_places=2)
    total       =   models.DecimalField(default=0.00,max_digits=100,decimal_places=2)
    timestamp   =   models.DateTimeField(auto_now_add=True)
    updated     =   models.DateTimeField(auto_now=True)
    
    objects = CartManager()
    
    def __str__(self):
        return str(self.id)
    
        
def m2mchanged_cart_receiver(sender,instance,action,*args,**kwargs):
    if action == 'post_add' or action == 'post_remove' or action == 'post_clear':
        prod = instance.products.all()
        total = 0 
        for x in prod:
            total += x.price
        if instance.subtotal != total:
            instance.subtotal = total
            instance.save()
    
m2m_changed.connect(m2mchanged_cart_receiver,sender=Cart.products.through)   
    
def pre_save_cart_receiver(sender,instance,*args,**kwargs):
    if instance.subtotal > 0:
        instance.total = Decimal(instance.subtotal) * Decimal(1.08)
    else:
        instance.total = instance.subtotal    
    
pre_save.connect(pre_save_cart_receiver, sender=Cart)    
        